Describe "Complete-PAOrder" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "Order from the pipeline" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Export-PACertFiles {}
            Mock -ModuleName Posh-ACME Update-PAOrder {}
            Mock -ModuleName Posh-ACME Install-PACertificate {}
            Mock -ModuleName Posh-ACME Import-Pem {
                [pscustomobject]@{
                    NotBefore = [DateTime]::Parse('2030-01-01T00:00:00Z')
                    NotAfter  = [DateTime]::Parse('2030-04-01T00:00:00Z')
                }
            }
        }

        It "Returns the certificate for the order it was given" {
            # the current order is 'example.com', so use a different one
            $order = Get-PAOrder -Name 'altname'
            $order | Add-Member 'status' 'valid' -Force
            $order | Add-Member 'certificate' 'https://acme.test/acme/cert/44444' -Force

            Mock -ModuleName Posh-ACME Get-PACertificate { [pscustomobject]@{ Name = $Name } }

            $cert = $order | Complete-PAOrder

            $cert.Name | Should -BeExactly 'altname'
            Should -Invoke Get-PACertificate -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'altname'
            }
        }
    }
}
