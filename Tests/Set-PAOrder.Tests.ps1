Describe "Set-PAOrder" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "Changing Profile" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Get-PAProfile {
                'profile1','profile2','profile3','profile4' | ForEach-Object { [pscustomobject]@{ Profile = $_ } }
            }
            Mock -ModuleName Posh-ACME Get-PACertificate { [pscustomobject]@{ Subject = 'CN=example.com' } }
            Mock -ModuleName Posh-ACME Export-PACertFiles {}
        }

        It "Doesn't re-export the cert files by itself" {
            Set-PAOrder -Name 'example.com' -Profile 'profile1'
            Should -Invoke Export-PACertFiles -ModuleName Posh-ACME -Times 0 -Exactly
        }

        It "Doesn't prevent re-exporting the cert files for <Setting>" -TestCases @(
            @{ Setting = 'FriendlyName';   Params = @{ FriendlyName = 'new friendly name'; Profile = 'profile2' } }
            @{ Setting = 'PfxPass';        Params = @{ PfxPass = 'newpass';                Profile = 'profile3' } }
            @{ Setting = 'PreferredChain'; Params = @{ PreferredChain = 'Some Root CA';    Profile = 'profile4' } }
        ) {
            Set-PAOrder -Name 'example.com' @Params
            Should -Invoke Export-PACertFiles -ModuleName Posh-ACME -Times 1 -Exactly
        }
    }
}
