Describe "Set-PAAccount" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "Renaming an account" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            $srvrDir = Join-Path $TestDrive 'srvr1'
            $curAcctFile = Join-Path $srvrDir 'current-account.txt'
        }

        It "Leaves the current account alone with -NoSwitch" {
            # acct1 is the current account; rename acct2 instead
            Set-PAAccount -ID 'acct2' -NewName 'renamed2' -NoSwitch

            (Get-Content $curAcctFile).Trim() | Should -BeExactly 'acct1'
            Join-Path $srvrDir 'renamed2' | Should -Exist
        }

        It "Follows the rename when it is the current account" {
            Set-PAAccount -ID 'acct1' -NewName 'renamed1' -NoSwitch

            (Get-Content $curAcctFile).Trim() | Should -BeExactly 'renamed1'
        }
    }
}