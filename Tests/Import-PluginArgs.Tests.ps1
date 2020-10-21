# Note: These tests depend on knowing the paramters associated with some of the actual
# DNS plugins. So if the parameters in the plugins change, the tests will need updating
# as well.

Describe "Import-PluginArgs" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')

        $fakeAcct1 = Get-Content "$PSScriptRoot\TestFiles\fakeAccount1.json" -Raw | ConvertFrom-Json
        $fakeAcct1.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
        $fakeAcct2 = Get-Content "$PSScriptRoot\TestFiles\fakeAccount2.json" -Raw | ConvertFrom-Json
        $fakeAcct2.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

        Mock -ModuleName Posh-ACME Get-DirFolder { return 'TestDrive:\' }
        New-Item "TestDrive:\$($fakeAcct1.id)" -ItemType Directory -ErrorAction Ignore
        New-Item "TestDrive:\$($fakeAcct2.id)" -ItemType Directory -ErrorAction Ignore
    }

    Context "Param Checks" {

        It "Works with no accounts at all" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $null }
            Mock -ModuleName Posh-ACME Get-PAAccount { $null } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $acct = TestData

                { Import-PluginArgs Route53 }                | Should -Throw
                { Import-PluginArgs Route53,Infoblox }       | Should -Throw
                { Import-PluginArgs Route53 -Account $acct } | Should -Throw
            }
        }

        It "Works with 1 inactive account" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $null }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Import-PluginArgs Route53 }                | Should -Throw
                { Import-PluginArgs Route53,Infoblox }       | Should -Throw
                { Import-PluginArgs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '99999'
                { Import-PluginArgs Route53 -Account $acct2Clone } | Should -Throw
            }
        }

        It "Works with 1 active account" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Import-PluginArgs Route53 }                | Should -Not -Throw
                { Import-PluginArgs Route53,Infoblox }       | Should -Not -Throw
                { Import-PluginArgs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '99999'
                { Import-PluginArgs Route53 -Account $acct2 } | Should -Throw
            }
        }

        It "Works with 0 active (2 total) accounts" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $null }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1,$fakeAcct2) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Import-PluginArgs Route53 }                | Should -Throw
                { Import-PluginArgs Route53,Infoblox }       | Should -Throw
                { Import-PluginArgs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '22222'
                { Import-PluginArgs Route53 -Account $acct2 } | Should -Not -Throw
                $acct2.id = '99999'
                { Import-PluginArgs Route53 -Account $acct2 } | Should -Throw
            }
        }

        It "Works with 1 active (2 total) account" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1,$fakeAcct2) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Import-PluginArgs Route53 }                | Should -Not -Throw
                { Import-PluginArgs Route53,Infoblox }       | Should -Not -Throw
                { Import-PluginArgs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '22222'
                { Import-PluginArgs Route53 -Account $acct2 } | Should -Not -Throw
                $acct2.id = '99999'
                { Import-PluginArgs Route53 -Account $acct2 } | Should -Throw
            }
        }
    }

    Context "No plugindata.xml" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
        }

        It "Does not throw" {
            InModuleScope Posh-ACME {
                { Import-PluginArgs } | Should -Not -Throw
            }
        }

        It "Returns nothing with no arguments" {
            InModuleScope Posh-ACME {
                $result = Import-PluginArgs
                $result | Should -BeOfType [hashtable]
                $result | Should -BeNullOrEmpty
            }
        }

        It "Returns nothing with plugin arguments" {
            InModuleScope Posh-ACME {
                $result = Import-PluginArgs Route53
                $result | Should -BeOfType [hashtable]
                $result | Should -BeNullOrEmpty
                $result = Import-PluginArgs Route53,Infoblox
                $result | Should -BeOfType [hashtable]
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context "Invalid plugindata.xml" {

        BeforeAll {
            Mock Get-PAAccount { $fakeAcct1 }
            'Unparseable data for Import-CliXml' | Out-File "TestDrive:\$($fakeAcct1.id)\plugindata.xml"
        }

        It "Throws with unparseable plugindata.xml" {
            InModuleScope Posh-ACME {
                { Import-PluginArgs }                  | Should -Throw
                { Import-PluginArgs Route53 }          | Should -Throw
                { Import-PluginArgs Route53,Infoblox } | Should -Throw
                { Import-PluginArgs FakePlugin }       | Should -Throw
            }
        }
    }

    Context "Valid plugindata.xml (no encryption)" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            $fakeData = @{
                IBUsername = 'fakeuser'
                IBPassword = 'fakepass'
                IBServer = 'fake.example.com'
                R53ProfileName = 'fake-profile'
                AliKeyId = 'fakeid'
                AliSecretInsecure = 'fakesecret'
            }
            $fakeData | Export-Clixml "TestDrive:\$($fakeAcct1.id)\plugindata.xml"
        }

        It "Does not throw with no arguments" {
            InModuleScope Posh-ACME {
                { Import-PluginArgs } | Should -Not -Throw
            }
        }

        It "Throws with invalid plugin" {
            InModuleScope Posh-ACME {
                { Import-PluginArgs FakePlugin } | Should -Throw
            }
        }

        It "Returns all saved data with no arguments" {
            InModuleScope Posh-ACME {
                $pargs = Import-PluginArgs
                $pargs                   | Should -BeOfType [hashtable]
                $pargs.Keys.Count        | Should -Be 6
                $pargs.IBUsername        | Should -Be 'fakeuser'
                $pargs.IBPassword        | Should -Be 'fakepass'
                $pargs.IBServer          | Should -Be 'fake.example.com'
                $pargs.R53ProfileName    | Should -Be 'fake-profile'
                $pargs.AliKeyId          | Should -Be 'fakeid'
                $pargs.AliSecretInsecure | Should -Be 'fakesecret'
            }
        }

        It "Returns plugin specific data with one plugin specified" {
            InModuleScope Posh-ACME {
                $pargs = Import-PluginArgs Route53
                $pargs                | Should -BeOfType [hashtable]
                $pargs.Keys.Count     | Should -Be 1
                $pargs.R53ProfileName | Should -Be 'fake-profile'
            }
        }

        It "Returns plugin specific data with multiple plugins specified" {
            InModuleScope Posh-ACME {
                $pargs = Import-PluginArgs Infoblox,Aliyun,Cloudflare
                $pargs                   | Should -BeOfType [hashtable]
                $pargs.Keys.Count        | Should -Be 5
                $pargs.IBUsername        | Should -Be 'fakeuser'
                $pargs.IBPassword        | Should -Be 'fakepass'
                $pargs.IBServer          | Should -Be 'fake.example.com'
                $pargs.AliKeyId          | Should -Be 'fakeid'
                $pargs.AliSecretInsecure | Should -Be 'fakesecret'
            }
        }

        It "Returns no data for plugins that have no saved data" {
            InModuleScope Posh-ACME {
                $pargs = Import-PluginArgs Cloudflare
                $pargs | Should -BeOfType [hashtable]
                $pargs | Should -BeNullOrEmpty
            }
        }

    }

}
