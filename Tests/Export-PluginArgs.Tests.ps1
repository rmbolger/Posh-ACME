Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

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


    }
}
