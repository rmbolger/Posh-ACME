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
        New-Item "TestDrive:\$($fakeAcct.id)" -ItemType Directory -ErrorAction SilentlyContinue

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
            $pDataFile = "TestDrive:\$($fakeAcct.id)\plugindata.xml"

            It "Does not throw" {
                Remove-Item $pDataFile -Force -EA SilentlyContinue
                { Export-PluginArgs $pargs Route53 } | Should -Not -Throw
            }
            It "Saves all args with 1 plugin" {
                Remove-Item $pDataFile -Force -EA SilentlyContinue
                Export-PluginArgs $pargs Route53
                $result = Import-Clixml $pDataFile
                $result | Should -BeOfType [hashtable]
                $result.Keys.Count | Should -Be 2
                $result.R53ProfileName | Should -BeExactly 'fake-profile'
            }
            It "Saves all args with multiple plugins" {
                Remove-Item $pDataFile -Force -EA SilentlyContinue
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
            'Unparseable data for Import-CliXml' | Out-File "TestDrive:\$($fakeAcct.id)\plugindata.xml"

            It "Throws with unparseable plugindata.xml" {
                { Export-PluginArgs $pargs Route53 }          | Should -Throw
                { Export-PluginArgs $pargs Route53,Infoblox } | Should -Throw
                { Export-PluginArgs $pargs FakePlugin }       | Should -Throw
            }

            Remove-Item "TestDrive:\$($fakeAcct.id)\plugindata.xml" -Force
        }

        Context "Valid plugindata.xml (no encryption)" {

            Mock Get-PAAccount { $fakeAcct }
            $pargs = @{
                IBUsername = 'fakeuser'
                IBPassword = 'fakepass'
                IBServer = 'fake.example.com'
                R53ProfileName = 'fake-profile'
                AliKeyId = 'fakeid'
                AliSecretInsecure = 'fakesecret'
            }



        }

    }
}
