Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

# Note: These tests depend on knowing the paramters associated with some of the actual
# DNS plugins. So if the parameters in the plugins change, the tests will need updating
# as well.

Describe "Export-PluginArgs" {

    InModuleScope Posh-ACME {

        $fakeAcct = Get-ChildItem "$PSScriptRoot\TestFiles\fakeAccount.json" | Get-Content -Raw | ConvertFrom-Json
        $fakeAcct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

        Mock Get-DirFolder { return 'TestDrive:\' }
        New-Item "TestDrive:\$($fakeAcct.id)" -ItemType Directory -ErrorAction Ignore
        $pDataFile = "TestDrive:\$($fakeAcct.id)\plugindata.xml"

        Context "No active account" {

            Mock Get-PAAccount { $null }
            $pargs = @{R53ProfileName='fake-profile'}

            It "Throws when no account specified" {
                { Export-PluginArgs $pargs Route53 }          | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox } | Should -Throw
                { Export-PluginArgs $pargs FakePlugin }       | Should -Throw
            }
            It "Throws when specified account doesn't exist on server" {
                Mock Get-PAAccount { @() } -ParameterFilter { $List }
                { Export-PluginArgs $pargs Route53 -Account $fakeAcct } | Should -Throw
            }
            It "Does not throw when specified account does exist on server" {
                Mock Get-PAAccount { @($fakeAcct) } -ParameterFilter { $List }
                { Export-PluginArgs $pargs Route53 -Account $fakeAcct } | Should -Not -Throw
            }
        }

        Context "No plugindata.xml" {

            Mock Get-PAAccount { $fakeAcct }
            $pargs = @{
                R53ProfileName='fake-profile'
                MyFakeParam='this has no plugin'
            }

            It "Does not throw" {
                Remove-Item $pDataFile -Force -EA Ignore
                { Export-PluginArgs $pargs Route53 } | Should -Not -Throw
            }
            It "Saves all args with 1 plugin" {
                Remove-Item $pDataFile -Force -EA Ignore
                Export-PluginArgs $pargs Route53
                $result = Import-Clixml $pDataFile
                $result | Should -BeOfType [hashtable]
                $result.Keys.Count | Should -Be 2
                $result.R53ProfileName | Should -BeExactly 'fake-profile'
            }
            It "Saves all args with multiple plugins" {
                Remove-Item $pDataFile -Force -EA Ignore
                Export-PluginArgs $pargs Route53,Infoblox
                $result = Import-Clixml $pDataFile
                $result | Should -BeOfType [hashtable]
                $result.Keys.Count | Should -Be 2
                $result.R53ProfileName | Should -BeExactly 'fake-profile'
            }
        }

        Context "Invalid plugindata.xml" {

            Mock Get-PAAccount { $fakeAcct }
            $pargs = @{
                R53ProfileName='fake-profile'
                MyFakeParam='this has no plugin'
            }
            'Unparseable data for Import-CliXml' | Out-File $pDataFile

            It "Throws with unparseable plugindata.xml" {
                { Export-PluginArgs $pargs Route53 }          | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox } | Should -Throw
                { Export-PluginArgs $pargs FakePlugin }       | Should -Throw
            }

            Remove-Item $pDataFile -Force
        }

        Context "Valid plugindata.xml (no encryption)" {

            Mock Get-PAAccount { $fakeAcct }

            It "Replaces old values for 1 plugin" {
                @{
                    IBUsername = 'old-user'
                    IBPassword = 'old-pass'
                } | Export-CliXml $pDataFile
                $pargs = @{
                    IBUsername = 'new-user'
                    IBPassword = 'new-pass'
                }
                Export-PluginArgs $pargs Infoblox
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
                $pargs = @{
                    IBUsername = 'new-user'
                    IBPassword = 'new-pass'
                    R53ProfileName = 'new-profile'
                }
                Export-PluginArgs $pargs Infoblox,Route53
                $result = Import-CliXml $pDataFile

                $result.Keys.Count | Should -Be 3
                $result.IBUsername | Should -BeExactly 'new-user'
                $result.IBPassword | Should -BeExactly 'new-pass'
                $result.R53ProfileName | Should -BeExactly 'new-profile'
            }

            It "Removes conflicting parameters for 1 plugin" {
                @{ R53ProfileName = 'old-profile' } | Export-CliXml $pDataFile
                $pargs = @{
                    R53AccessKey = 'new-key'
                    R53SecretKeyInsecure = 'new-secret'
                }
                Export-PluginArgs $pargs Route53
                $result = Import-Clixml $pDataFile

                $result.Keys.Count | Should -Be 2
                $result.R53AccessKey | Should -BeExactly 'new-key'
                $result.R53SecretKeyInsecure | Should -BeExactly 'new-secret'
            }

            It "Removes conflicting parameters for multiple plugins" {
                @{
                    R53ProfileName = 'old-profile'
                    AZAccessToken = 'old-token'
                } | Export-CliXml $pDataFile
                $pargs = @{
                    R53AccessKey = 'new-key'
                    R53SecretKeyInsecure = 'new-secret'
                    AZAppUsername = 'new-user'
                    AZAppPasswordInsecure = 'new-pass'
                }
                Export-PluginArgs $pargs Route53,Azure
                $result = Import-Clixml $pDataFile

                $result.Keys.Count | Should -Be 4
                $result.R53AccessKey | Should -BeExactly 'new-key'
                $result.R53SecretKeyInsecure | Should -BeExactly 'new-secret'
                $result.AZAppUsername | Should -BeExactly 'new-user'
                $result.AZAppPasswordInsecure | Should -BeExactly 'new-pass'
            }

            It "Does not change parameters unassociated with plugin" {
                @{
                    R53ProfileName = 'old-profile'
                    AZAccessToken = 'old-token'
                } | Export-CliXml $pDataFile
                $pargs = @{
                    R53ProfileName = 'new-profile'
                }
                Export-PluginArgs $pargs Route53
                $result = Import-Clixml $pDataFile

                $result.Keys.Count | Should -Be 2
                $result.R53ProfileName | Should -BeExactly 'new-profile'
                $result.AZAccessToken | Should -BeExactly 'old-token'
            }

            It "Includes all new parameters unassociated with plugin" {
                @{
                    R53ProfileName = 'old-profile'
                } | Export-CliXml $pDataFile
                $pargs = @{
                    R53ProfileName = 'new-profile'
                    FakeParam1 = 'fake1'
                    FakeParam2 = 'fake2'
                }
                Export-PluginArgs $pargs Route53
                $result = Import-Clixml $pDataFile

                $result.Keys.Count | Should -Be 3
                $result.R53ProfileName | Should -BeExactly 'new-profile'
                $result.FakeParam1 | Should -BeExactly 'fake1'
                $result.FakeParam2 | Should -BeExactly 'fake2'
            }

        }

    }
}
