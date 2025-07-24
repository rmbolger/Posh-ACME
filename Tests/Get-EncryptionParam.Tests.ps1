Describe "Get-EncryptionParam" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "No Alt Encryption" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            $env:POSHACME_VAULT_NAME = $null

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Returns Empty Hashtable" {
            InModuleScope -ModuleName Posh-ACME {
                $encParam = Get-EncryptionParam -Account (Get-PAAccount)

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 0
            }
        }
    }

    Context "SSKey on Account" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            $env:POSHACME_VAULT_NAME = $null

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Returns Key Splat" {
            InModuleScope -ModuleName Posh-ACME {
                # add a fake key to the account
                $acct = Get-PAAccount
                $acct | Add-Member 'sskey' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -Force

                $encParam = Get-EncryptionParam -Account $acct

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 1
                'Key'           | Should -BeIn $encParam.Keys
                ConvertTo-Base64Url $encParam.Key | Should -Be 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
            }
        }
    }

    Context "SSKey in Vault" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            $env:POSHACME_VAULT_NAME = 'fake-vault'

            # tweak the account to indicate a VAULT sskey
            $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
            $acct | Add-Member 'sskey' 'VAULT' -Force
            $acct | Add-Member 'VaultGuid' 'fakeguid' -Force
            $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Handles Missing SecretManagement Module" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Command {}
                Mock Write-Error {}

                $encParam = Get-EncryptionParam -Account (Get-PAAccount)

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 0

                Should -Invoke Write-Error -Times 1 -Exactly -ParameterFilter {
                    $Message -like '*SecretManagement module not found*'
                }
            }
        }

        It "Handles Missing Vault Name" {
            InModuleScope -ModuleName Posh-ACME {

                Mock Write-Error {}
                $env:POSHACME_VAULT_NAME = $null

                $encParam = Get-EncryptionParam -Account (Get-PAAccount)

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 0

                Should -Invoke Write-Error -Times 1 -Exactly -ParameterFilter {
                    $Message -like '*Vault name not found*'
                }

                $env:POSHACME_VAULT_NAME = 'fake-vault'
            }
        }

        It "Retrieves Vault Key" {
            InModuleScope -ModuleName Posh-ACME {

                Mock Write-Error {}
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }

                $encParam = Get-EncryptionParam -Account (Get-PAAccount)

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 1
                'Key'           | Should -BeIn $encParam.Keys
                ConvertTo-Base64Url $encParam.Key | Should -Be 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'

                Should -Invoke Get-Secret -Times 1 -Exactly -ParameterFilter {
                    $Vault -eq 'fake-vault' -and $Name -eq 'poshacme-fakeguid-sskey'
                }

            }
        }

        It "Retrieves Vault Key - Custom Template" {
            InModuleScope -ModuleName Posh-ACME {

                Mock Write-Error {}
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
                $env:POSHACME_VAULT_SECRET_TEMPLATE = 'a-{0}-b'

                $encParam = Get-EncryptionParam -Account (Get-PAAccount)

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 1
                'Key'           | Should -BeIn $encParam.Keys
                ConvertTo-Base64Url $encParam.Key | Should -Be 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'

                Should -Invoke Get-Secret -Times 1 -Exactly -ParameterFilter {
                    $Vault -eq 'fake-vault' -and $Name -eq 'a-fakeguid-b'
                }

                $env:POSHACME_VAULT_SECRET_TEMPLATE = $null
            }
        }

        It "Tries to Unlock Vault" {
            InModuleScope -ModuleName Posh-ACME {

                Mock Write-Error {}
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
                Mock Unlock-SecretVault {} #-Name $vaultName -Password $ssPass
                $env:POSHACME_VAULT_PASS = 'fakepass'

                $encParam = Get-EncryptionParam -Account (Get-PAAccount)

                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 1
                'Key'           | Should -BeIn $encParam.Keys
                ConvertTo-Base64Url $encParam.Key | Should -Be 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'

                Should -Invoke Unlock-SecretVault -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'fake-vault' -and
                    'fakepass' -eq [pscredential]::new('a',$Password).GetNetworkCredential().Password
                }

                Should -Invoke Get-Secret -Times 1 -Exactly -ParameterFilter {
                    $Vault -eq 'fake-vault' -and $Name -eq 'poshacme-fakeguid-sskey'
                }

                $env:POSHACME_VAULT_PASS = $null
            }
        }

        It "Handles Get-Secret Failure" {
            InModuleScope -ModuleName Posh-ACME {

                Mock Write-Error {}
                Mock Get-Secret { throw 'fake exception' }

                $encParam = Get-EncryptionParam -Account (Get-PAAccount) -EA Ignore

                $?              | Should -BeFalse
                $encParam       | Should -BeOfType [hashtable]
                $encParam.Count | Should -Be 0

            }
        }

    }
}
