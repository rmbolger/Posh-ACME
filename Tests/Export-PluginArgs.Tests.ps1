# Note: These tests depend on knowing the paramters associated with some of the actual
# DNS plugins. So if the parameters in the plugins change, the tests will need updating
# as well.

Describe "Export-PluginArgs" {

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

        BeforeAll {
            Mock -ModuleName Posh-ACME Export-CliXml { }
        }

        It "Works with no accounts at all" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $null }
            Mock -ModuleName Posh-ACME Get-PAAccount { $null } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $pargs = @{R53ProfileName='fake-profile'}
                $acct = TestData

                { Export-PluginArgs $pargs Route53 }                | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox }       | Should -Throw
                { Export-PluginArgs $pargs Route53 -Account $acct } | Should -Throw
            }
        }

        It "Works with 1 inactive account" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $null }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $pargs = @{R53ProfileName='fake-profile'}
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Export-PluginArgs $pargs Route53 }                | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox }       | Should -Throw
                { Export-PluginArgs $pargs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '99999'
                { Export-PluginArgs $pargs Route53 -Account $acct2Clone } | Should -Throw
            }
        }

        It "Works with 1 active account" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $pargs = @{R53ProfileName='fake-profile'}
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Export-PluginArgs $pargs Route53 }                | Should -Not -Throw
                { Export-PluginArgs $pargs Route53,Infoblox }       | Should -Not -Throw
                { Export-PluginArgs $pargs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '99999'
                { Export-PluginArgs $pargs Route53 -Account $acct2 } | Should -Throw
            }
        }

        It "Works with 0 active (2 total) accounts" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $null }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1,$fakeAcct2) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $pargs = @{R53ProfileName='fake-profile'}
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Export-PluginArgs $pargs Route53 }                | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox }       | Should -Throw
                { Export-PluginArgs $pargs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '22222'
                { Export-PluginArgs $pargs Route53 -Account $acct2 } | Should -Not -Throw
                $acct2.id = '99999'
                { Export-PluginArgs $pargs Route53 -Account $acct2 } | Should -Throw
            }
        }

        It "Works with 1 active (2 total) account" {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            Mock -ModuleName Posh-ACME Get-PAAccount { @($fakeAcct1,$fakeAcct2) } -ParameterFilter { $List }
            Mock -ModuleName Posh-ACME TestData { $fakeAcct1 }

            InModuleScope Posh-ACME {
                $pargs = @{R53ProfileName='fake-profile'}
                $acct = TestData
                $acct2 = [pscustomobject]@{id='99999';PSTypeName='PoshACME.PAAccount'}

                { Export-PluginArgs $pargs Route53 }                | Should -Not -Throw
                { Export-PluginArgs $pargs Route53,Infoblox }       | Should -Not -Throw
                { Export-PluginArgs $pargs Route53 -Account $acct } | Should -Not -Throw
                $acct2.id = '22222'
                { Export-PluginArgs $pargs Route53 -Account $acct2 } | Should -Not -Throw
                $acct2.id = '99999'
                { Export-PluginArgs $pargs Route53 -Account $acct2 } | Should -Throw
            }
        }
    }

    Context "No plugindata.xml" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            $pDataFile = "TestDrive:\$($fakeAcct1.id)\plugindata.xml"
        }

        It "Saves all plugin args (1 plugin)" {
            InModuleScope Posh-ACME {
                $pargs = @{
                    R53ProfileName='fake-profile'
                    MyFakeParam='this has no plugin'
                }
                Export-PluginArgs $pargs Route53
            }

            $pDataFile | Should -Exist
            $result = Import-Clixml $pDataFile
            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -Be 2
            $result.R53ProfileName | Should -BeExactly 'fake-profile'
            $result.MyFakeParam | Should -BeExactly 'this has no plugin'
        }

        It "Saves all plugin args (2 plugins)" {
            InModuleScope Posh-ACME {
                $pargs = @{
                    R53ProfileName='fake-profile'
                    IBUsername = 'admin'
                    MyFakeParam='this has no plugin'
                }
                Export-PluginArgs $pargs Route53,Infoblox
            }

            $pDataFile | Should -Exist -EA Stop
            $result = Import-Clixml $pDataFile
            $result                | Should -BeOfType [hashtable]
            $result.Keys.Count     | Should -Be 3
            $result.R53ProfileName | Should -BeExactly 'fake-profile'
            $result.IBUsername     | Should -BeExactly 'admin'
            $result.MyFakeParam    | Should -BeExactly 'this has no plugin'
        }
    }

    Context "Invalid plugindata.xml" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            $pDataFile = "TestDrive:\$($fakeAcct1.id)\plugindata.xml"
            'Unparseable data for Import-CliXml' | Out-File $pDataFile
        }

        It "Throws" {
            InModuleScope Posh-ACME {
                $pargs = @{
                    R53ProfileName='fake-profile'
                    MyFakeParam='this has no plugin'
                }
                { Export-PluginArgs $pargs Route53 }          | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox } | Should -Throw
                { Export-PluginArgs $pargs FakePlugin }       | Should -Throw
            }
        }
    }

    Context "Valid plugindata.xml (no encryption)" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { $fakeAcct1 }
            $pDataFile = "TestDrive:\$($fakeAcct1.id)\plugindata.xml"
            'Unparseable data for Import-CliXml' | Out-File $pDataFile
        }

        It "Replaces old values for 1 plugin" {
            @{
                IBUsername = 'old-user'
                IBPassword = 'old-pass'
            } | Export-CliXml $pDataFile

            InModuleScope Posh-ACME {
                $pargs = @{
                    IBUsername = 'new-user'
                    IBPassword = 'new-pass'
                }
                Export-PluginArgs $pargs Infoblox
            }

            $pDataFile | Should -Exist -EA Stop
            $result = Import-CliXml $pDataFile
            $result.Keys.Count | Should -Be 2
            $result.IBUsername | Should -BeExactly 'new-user'
            $result.IBPassword | Should -BeExactly 'new-pass'
        }

        It "Replaces old values for multiple plugins" {
            @{
                IBUsername = 'old-user'
                IBPassword = 'old-pass'
                R53ProfileName = 'old-profile'
            } | Export-CliXml $pDataFile

            InModuleScope Posh-ACME {
                $pargs = @{
                    IBUsername = 'new-user'
                    IBPassword = 'new-pass'
                    R53ProfileName = 'new-profile'
                }
                Export-PluginArgs $pargs Infoblox,Route53
            }

            $pDataFile | Should -Exist -EA Stop
            $result = Import-CliXml $pDataFile
            $result.Keys.Count     | Should -Be 3
            $result.IBUsername     | Should -BeExactly 'new-user'
            $result.IBPassword     | Should -BeExactly 'new-pass'
            $result.R53ProfileName | Should -BeExactly 'new-profile'
        }

        It "Removes conflicting parameters for 1 plugin" {
            @{ R53ProfileName = 'old-profile' } | Export-CliXml $pDataFile

            InModuleScope Posh-ACME {
                $pargs = @{
                    R53AccessKey = 'new-key'
                    R53SecretKeyInsecure = 'new-secret'
                }
                Export-PluginArgs $pargs Route53
            }

            $pDataFile | Should -Exist -EA Stop
            $result = Import-Clixml $pDataFile
            $result.Keys.Count           | Should -Be 2
            $result.R53AccessKey         | Should -BeExactly 'new-key'
            $result.R53SecretKeyInsecure | Should -BeExactly 'new-secret'
        }

        It "Removes conflicting parameters for multiple plugins" {
            @{
                R53ProfileName = 'old-profile'
                AZAccessToken = 'old-token'
            } | Export-CliXml $pDataFile

            InModuleScope Posh-ACME {
                $pargs = @{
                    R53AccessKey = 'new-key'
                    R53SecretKeyInsecure = 'new-secret'
                    AZAppUsername = 'new-user'
                    AZAppPasswordInsecure = 'new-pass'
                }
                Export-PluginArgs $pargs Route53,Azure
            }

            $pDataFile | Should -Exist
            $result = Import-Clixml $pDataFile
            $result.Keys.Count            | Should -Be 4
            $result.R53AccessKey          | Should -BeExactly 'new-key'
            $result.R53SecretKeyInsecure  | Should -BeExactly 'new-secret'
            $result.AZAppUsername         | Should -BeExactly 'new-user'
            $result.AZAppPasswordInsecure | Should -BeExactly 'new-pass'
        }

        It "Does not change parameters unassociated with plugin" {
            @{
                R53ProfileName = 'old-profile'
                AZAccessToken = 'old-token'
            } | Export-CliXml $pDataFile

            InModuleScope Posh-ACME {
                $pargs = @{
                    R53ProfileName = 'new-profile'
                }
                Export-PluginArgs $pargs Route53
            }

            $pDataFile | Should -Exist -EA Stop
            $result = Import-Clixml $pDataFile
            $result.Keys.Count     | Should -Be 2
            $result.R53ProfileName | Should -BeExactly 'new-profile'
            $result.AZAccessToken  | Should -BeExactly 'old-token'
        }

        It "Includes all new parameters unassociated with plugin" {
            @{
                R53ProfileName = 'old-profile'
            } | Export-CliXml $pDataFile

            InModuleScope Posh-ACME {
                $pargs = @{
                    R53ProfileName = 'new-profile'
                    FakeParam1 = 'fake1'
                    FakeParam2 = 'fake2'
                }
                Export-PluginArgs $pargs Route53
            }

            $pDataFile | Should -Exist -EA Stop
            $result = Import-Clixml $pDataFile
            $result.Keys.Count     | Should -Be 3
            $result.R53ProfileName | Should -BeExactly 'new-profile'
            $result.FakeParam1     | Should -BeExactly 'fake1'
            $result.FakeParam2     | Should -BeExactly 'fake2'
        }

    }

}
