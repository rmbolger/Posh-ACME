# Note: These tests depend on knowing the paramters associated with some of the actual
# DNS plugins. So if the parameters in the plugins change, the tests will need updating
# as well.

Describe "Get-PAPluginArgs" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "No account" {
        It "Throws" {
            Mock -ModuleName Posh-ACME Get-PAAccount {}
            { Get-PAPluginArgs } | Should -Throw "*No ACME account*"
        }
    }

    Context "Active order" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Write-Warning {}
            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "No params - returns active args" {
            { Get-PAPluginArgs } | Should -Not -Throw
            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME

            $result = Get-PAPluginArgs
            $result                      | Should -BeOfType [hashtable]
            $result.Keys                 | Should -HaveCount 2
            $result.R53AccessKey         | Should -Be 'xxxxx'
            $result.R53SecretKeyInsecure | Should -Be 'yyyyy'
        }

        It "Fake domain - returns nothing" {
            { Get-PAPluginArgs 'fakedomain' } | Should -Not -Throw
            Should -Invoke Write-Warning -ModuleName Posh-ACME

            $result = Get-PAPluginArgs 'fakedomain'
            $result      | Should -BeOfType [hashtable]
            $result.Keys | Should -HaveCount 0
        }

        It "Valid domain - returns correct args" {
            { Get-PAPluginArgs '*.example.com' } | Should -Not -Throw
            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME

            $result = Get-PAPluginArgs '*.example.com'
            $result                 | Should -BeOfType [hashtable]
            $result.Keys            | Should -HaveCount 2
            $result.DOToken         | Should -Be 'xxxxx'
            $result.DSTokenInsecure | Should -Be 'yyyyy'
        }
    }

    Context "No current order" {
        # pretend there's no current order
        BeforeAll {
            Mock -ModuleName Posh-ACME Write-Warning {}
            InModuleScope Posh-ACME { $script:Order = $null }
        }

        It "Valid domain - returns correct args" {
            { Get-PAPluginArgs 'example.com' } | Should -Not -Throw
            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME

            $result = Get-PAPluginArgs 'example.com'
            $result                      | Should -BeOfType [hashtable]
            $result.Keys                 | Should -HaveCount 2
            $result.R53AccessKey         | Should -Be 'xxxxx'
            $result.R53SecretKeyInsecure | Should -Be 'yyyyy'
        }

        It "Fake domain - returns nothing" {
            { Get-PAPluginArgs 'fakedomain' } | Should -Not -Throw
            Should -Invoke Write-Warning -ModuleName Posh-ACME

            $result = Get-PAPluginArgs 'fakedomain'
            $result      | Should -BeOfType [hashtable]
            $result.Keys | Should -HaveCount 0
        }

        # reset the internal module state
        AfterAll { InModuleScope Posh-ACME { Import-PAConfig } }
    }

    Context "Data Types" {
        BeforeAll {
            # replace the active order's plugin args samples of all the
            # data types we're expecting
            $ss = 'xxxxx' | ConvertTo-SecureString -AsPlainText -Force
            @{
                String = 'normalstring'
                StringArray = 'a','b','c'
                SecureString = [pscustomobject]@{
                    origType = 'securestring'
                    value = $ss | ConvertFrom-SecureString
                }
                Credential = [pscustomobject]@{
                    origType = 'pscredential'
                    user = 'admin'
                    pass = $ss | ConvertFrom-SecureString
                }
                Switch = $true
                Number = 123
                Hashtable = @{
                    'domain1' = @('d','e','f')
                    'domain2' = @('g','h','i')
                }
            } | ConvertTo-Json -Depth 10 | Out-File 'TestDrive:\srvr1\acct1\example.com\pluginargs.json' -Encoding utf8
        }

        It "Returns args properly" {
            $result = Get-PAPluginArgs

            $result      | Should -BeOfType [hashtable]
            $result.Keys | Should -HaveCount 7

            $result.String | Should -Be 'normalstring'

            $result.StringArray | Should -HaveCount 3
            $result.StringArray | Should -Be 'a','b','c'

            $result.SecureString | Should -BeOfType [SecureString]
            $ssPlain = [pscredential]::new('a',$result.SecureString).GetNetworkCredential().Password
            $ssPlain     | Should -Be 'xxxxx'

            $result.Credential          | Should -BeOfType [PSCredential]
            $result.Credential.Username | Should -Be 'admin'
            $ssPlain = $result.Credential.GetNetworkCredential().Password
            $ssPlain                    | Should -Be 'xxxxx'

            $result.Switch | Should -BeOfType [bool]
            $result.Switch | Should -BeTrue

            $result.Number | Should -BeExactly 123

            $result.Hashtable | Should -BeOfType [hashtable]
            $result.Hashtable.domain1 | Should -Not -BeNullOrEmpty
            $result.Hashtable.domain2 | Should -Not -BeNullOrEmpty
            $result.Hashtable.domain1 | Should -HaveCount 3
            $result.Hashtable.domain1 | Should -Be 'd','e','f'
            $result.Hashtable.domain2 | Should -HaveCount 3
            $result.Hashtable.domain2 | Should -Be 'g','h','i'
        }

    }
}
