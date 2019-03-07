Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "Import-PluginArgs" {

    InModuleScope Posh-ACME {

        $fakeAcct = Get-ChildItem "$PSScriptRoot\TestFiles\fakeAccount.json" | Get-Content -Raw | ConvertFrom-Json
        $fakeAcct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

        Mock Get-DirFolder { return 'TestDrive:\' }
        New-Item "TestDrive:\$($fakeAcct.id)" -ItemType Directory -ErrorAction SilentlyContinue

        Context "No active account" {

            Mock Get-PAAccount { $null }

            It "Throws when no account specified" {
                { Import-PluginArgs }                  | Should -Throw
                { Import-PluginArgs Route53 }          | Should -Throw
                { Import-PluginArgs Route53,Infoblox } | Should -Throw
                { Import-PluginArgs FakePlugin }       | Should -Throw
            }
            It "Throws when specified account doesn't exist on server" {
                Mock Get-PAAccount { @() } -ParameterFilter { $List }
                { Import-PluginArgs -Account $fakeAcct }         | Should -Throw
                { Import-PluginArgs Route53 -Account $fakeAcct } | Should -Throw
            }
            It "Does not throw when specified account does exist on server" {
                Mock Get-PAAccount { @($fakeAcct) } -ParameterFilter { $List }
                { Import-PluginArgs -Account $fakeAcct }         | Should -Not -Throw
                { Import-PluginArgs Route53 -Account $fakeAcct } | Should -Not -Throw
            }
        }

        Context "No plugindata.xml" {

            Mock Get-PAAccount { $fakeAcct }

            It "Does not throw" {
                { Import-PluginArgs } | Should -Not -Throw
            }
            It "Returns nothing with no arguments" {
                Import-PluginArgs | Should -BeNullOrEmpty
            }
            It "Returns nothing with plugin arguments" {
                Import-PluginArgs Route53          | Should -BeNullOrEmpty
                Import-PluginArgs Route53,Infoblox | Should -BeNullOrEmpty
            }
        }

        Context "Invalid plugindata.xml" {

            Mock Get-PAAccount { $fakeAcct }
            'Unparseable data for Import-CliXml' | Out-File "TestDrive:\$($fakeAcct.id)\plugindata.xml"

            It "Throws with unparseable plugindata.xml" {
                { Import-PluginArgs }                  | Should -Throw
                { Import-PluginArgs Route53 }          | Should -Throw
                { Import-PluginArgs Route53,Infoblox } | Should -Throw
                { Import-PluginArgs FakePlugin }       | Should -Throw
            }

            Remove-Item "TestDrive:\$($fakeAcct.id)\plugindata.xml" -Force
        }

        Context "Valid plugindata.xml (no encryption)" {

            Mock Get-PAAccount { $fakeAcct }
            $fakeData = @{
                IBUsername = 'fakeuser'
                IBPassword = 'fakepass'
                IBServer = 'fake.example.com'
                R53ProfileName = 'fake-profile'
                AliKeyId = 'fakeid'
                AliSecretInsecure = 'fakesecret'
            }
            $fakeData | Export-Clixml "TestDrive:\$($fakeAcct.id)\plugindata.xml"

            It "Does not throw with no arguments" {
                { Import-PluginArgs } | Should -Not -Throw
            }
            It "Throws with invalid plugin" {
                { Import-PluginArgs FakePlugin } | Should -Throw
            }
            $pargs = Import-PluginArgs
            It "Returns a hashtable" {
                $pargs | Should -BeOfType [hashtable]
            }
            It "Returns all saved data with no arguments" {
                $pargs.Keys.Count        | Should -Be 6
                $pargs.IBUsername        | Should -Be 'fakeuser'
                $pargs.IBPassword        | Should -Be 'fakepass'
                $pargs.IBServer          | Should -Be 'fake.example.com'
                $pargs.R53ProfileName    | Should -Be 'fake-profile'
                $pargs.AliKeyId          | Should -Be 'fakeid'
                $pargs.AliSecretInsecure | Should -Be 'fakesecret'
            }
            It "Returns plugin specific data with one plugin specified" {
                $pargs = Import-PluginArgs Route53
                $pargs.Keys.Count | Should -Be 1
                $pargs.R53ProfileName | Should -Be 'fake-profile'
            }
            It "Returns plugin specific data with multiple plugins specified" {
                $pargs = Import-PluginArgs Infoblox,Aliyun,Cloudflare
                $pargs.Keys.Count        | Should -Be 5
                $pargs.IBUsername        | Should -Be 'fakeuser'
                $pargs.IBPassword        | Should -Be 'fakepass'
                $pargs.IBServer          | Should -Be 'fake.example.com'
                $pargs.AliKeyId          | Should -Be 'fakeid'
                $pargs.AliSecretInsecure | Should -Be 'fakesecret'
            }
            It "Returns no data for plugins that have no saved data" {
                $pargs = Import-PluginArgs Cloudflare
                $pargs | Should -BeNullOrEmpty
            }

            Remove-Item "TestDrive:\$($fakeAcct.id)\plugindata.xml" -Force
        }

    }
}
