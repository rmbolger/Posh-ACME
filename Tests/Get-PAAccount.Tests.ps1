Describe "Get-PAAccount" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "No Server" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Get-PAServer {}
        }

        It "Throws Error" -TestCases @(
            @{ splat = @{                           } }
            @{ splat = @{             Refresh=$true } }
            @{ splat = @{ ID='acct1';               } }
            @{ splat = @{ ID='acct1'; Refresh=$true } }
            @{ splat = @{ ID='fake1';               } }
            @{ splat = @{ List=$true                } }
            @{ splat = @{ List=$true; Refresh=$true } }
        ) {
            { Get-PAAccount @splat } | Should -Throw "*No ACME Server*"
        }
    }

    Context "No Accounts Created" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # remove all accounts
            Get-ChildItem 'TestDrive:\srvr1' -Exclude 'dir.json' | Remove-Item -Recurse -Force

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Returns No Results" -TestCases @(
            @{ splat = @{                           } }
            @{ splat = @{             Refresh=$true } }
            @{ splat = @{ ID='acct1';               } }
            @{ splat = @{ ID='acct1'; Refresh=$true } }
            @{ splat = @{ List=$true                } }
            @{ splat = @{ List=$true; Refresh=$true } }
        ) {
            { Get-PAAccount @splat } | Should -Not -Throw
            Get-PAAccount @splat | Should -BeNullOrEmpty
        }
    }

    Context "No Current Account" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # remove the current account
            Remove-Item 'TestDrive:\srvr1\current-account.txt'

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Returns No Current Results" -TestCases @(
            @{ splat = @{                           } }
            @{ splat = @{             Refresh=$true } }
        ) {
            { Get-PAAccount @splat } | Should -Not -Throw
            Get-PAAccount @splat | Should -BeNullOrEmpty
        }
    }

    Context "Test Config" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Update-PAAccount {}
        }

        It "Returns Current and Specific Accounts" -TestCases @(
            @{ splat = @{                           }; ID='acct1' }
            @{ splat = @{             Refresh=$true }; ID='acct1' }
            @{ splat = @{ ID='acct1';               }; ID='acct1' }
            @{ splat = @{ ID='acct1'; Refresh=$true }; ID='acct1' }
            @{ splat = @{ ID='acct2';               }; ID='acct2' }
            @{ splat = @{ ID='acct3';               }; ID='acct3' }
        ) {
            $acct = Get-PAAccount @splat

            $acct    | Should -Not -BeNullOrEmpty
            $acct.id | Should -Be $ID
            $acct.Folder | Should -Be (Join-Path (Join-Path $TestDrive 'srvr1') $ID)
            if ($splat.Refresh) {
                Should -Invoke Update-PAAccount -Exactly 1 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Update-PAAccount -ModuleName Posh-ACME
            }
        }

        It "Returns Correct Account Details" -TestCases @(
            @{ id='acct1'; status='valid';       alg='ES256'; KeyLength='ec-256'; location='https://acme.test/acme/acct/11111' }
            @{ id='acct2'; status='valid';       alg='ES384'; KeyLength='ec-384'; location='https://acme.test/acme/acct/22222' }
            @{ id='acct3'; status='deactivated'; alg='ES512'; KeyLength='ec-521'; location='https://acme.test/acme/acct/33333' }
        ) {
            $acct = Get-PAAccount -ID $id

            $acct.id        | Should -Be $id
            $acct.status    | Should -Be $status
            $acct.alg       | Should -Be $alg
            $acct.KeyLength | Should -Be $KeyLength
            $acct.location  | Should -Be $location
        }

        It "Migrates all legacy accounts before loading the current account" {
            $acctFiles = Get-ChildItem (Join-Path $TestDrive 'srvr1\*\acct.json')
            foreach ($acctFile in $acctFiles) {
                $legacyAcct = Get-Content $acctFile.FullName -Raw | ConvertFrom-Json
                $legacyAcct.PSObject.Properties.Remove('pubkey')
                $legacyAcct.PSObject.Properties.Remove('thumbprint')
                $legacyAcct | ConvertTo-Json -Depth 5 | Set-Content $acctFile.FullName
            }

            InModuleScope Posh-ACME { Import-PAConfig -Level Account }

            $currentAccount = Get-PAAccount
            $currentAccount.id | Should -BeExactly 'acct1'
            $currentAccount.pubkey | Should -Not -BeNullOrEmpty
            $currentAccount.thumbprint | Should -Not -BeNullOrEmpty

            $accounts = @(Get-PAAccount -List)
            $accounts.Count | Should -Be 3
            foreach ($account in $accounts) {
                $account.pubkey | Should -Not -BeNullOrEmpty
                $account.thumbprint | Should -Not -BeNullOrEmpty

                $accountFile = Join-Path $account.Folder 'acct.json'
                $savedAccount = Get-Content $accountFile -Raw | ConvertFrom-Json
                $savedAccount.pubkey | Should -Not -BeNullOrEmpty
                $savedAccount.thumbprint | Should -BeExactly $account.thumbprint
            }
        }

        It "Returns List Results" -TestCases @(
            @{ splat = @{ List=$true                } }
            @{ splat = @{ List=$true; Refresh=$true } }
        ) {
            $accts = Get-PAAccount @splat

            $accts                          | Should -Not -BeNullOrEmpty
            $accts.Count                    | Should -Be 3
            $accts[0].PSObject.TypeNames[0] | Should -Be 'PoshACME.PAAccount'
            $accts[1].PSObject.TypeNames[0] | Should -Be 'PoshACME.PAAccount'
            $accts[2].PSObject.TypeNames[0] | Should -Be 'PoshACME.PAAccount'
            $accts | ForEach-Object {
                $_.pubkey | Should -Not -BeNullOrEmpty
                $_.thumbprint | Should -Not -BeNullOrEmpty
            }

            if ($splat.Refresh) {
                # only expecting 2 calls because one account is deactivated
                Should -Invoke Update-PAAccount -Exactly 2 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Update-PAAccount -ModuleName Posh-ACME
            }
        }

        It "Returns Filtered List Results" -TestCases @(
            @{ splat = @{ List=$true; Status='valid'                                                 }; ResultCount=2 }
            @{ splat = @{ List=$true; Status='deactivated'                                           }; ResultCount=1 }
            @{ splat = @{ List=$true; Status='revoked'                                               }; ResultCount=0 }
            @{ splat = @{ List=$true;                      KeyLength='2048'                          }; ResultCount=0 }
            @{ splat = @{ List=$true;                      KeyLength='ec-256'                        }; ResultCount=1 }
            @{ splat = @{ List=$true;                      KeyLength='ec-384'                        }; ResultCount=1 }
            @{ splat = @{ List=$true;                                          Contact='me@ex.test'  }; ResultCount=1 }
            @{ splat = @{ List=$true;                                          Contact='me2@ex.test' }; ResultCount=0 }
            @{ splat = @{ List=$true;                                          Contact='me@ex.test','me2@ex.test' }; ResultCount=1 }
            @{ splat = @{ List=$true; Status='valid';      KeyLength='ec-384'; Contact='me@ex.test'  }; ResultCount=1 }
        ) {
            $accts = @(Get-PAAccount @splat)

            $accts.Count | Should -Be $ResultCount
        }
    }

}
