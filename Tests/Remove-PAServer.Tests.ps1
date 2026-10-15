Describe "Remove-PAServer" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "Removing multiple servers from the pipeline" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Set-PAServer {}
            Mock -ModuleName Posh-ACME Import-PAConfig {}
        }

        It "Clears the current server rather than switching back to a deleted one" {
            # servers sort as le-stage, srvr1, srvr2 and srvr1 is the current one,
            # so the first item sets the switch-back flag and srvr1 follows it
            Get-PAServer -List | Remove-PAServer -Force

            Join-Path $TestDrive 'current-server.txt' | Should -Not -Exist
        }
    }
}