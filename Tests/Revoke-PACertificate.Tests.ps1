Describe "Revoke-PACertificate" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "Multiple certificates from the pipeline" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Invoke-ACME {}
            Mock -ModuleName Posh-ACME Write-Warning {}
        }

        It "Falls back to the account key when a cert's key file is missing" {
            $orderDir = Join-Path (Join-Path (Join-Path $TestDrive 'srvr1') 'acct1') 'example.com'
            $certFile = Join-Path $orderDir 'cert.cer'

            @(
                [pscustomobject]@{ CertFile = $certFile; KeyFile = (Join-Path $orderDir 'cert.key') }
                [pscustomobject]@{ CertFile = $certFile; KeyFile = (Join-Path $orderDir 'nope.key') }
            ) | Revoke-PACertificate -Force -Confirm:$false

            Should -Invoke Invoke-ACME -ModuleName Posh-ACME -Times 2 -Exactly
            # the second cert has no usable key, so it must not reuse the first one's
            Should -Invoke Invoke-ACME -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter {
                $null -eq $Key
            }
        }
    }
}