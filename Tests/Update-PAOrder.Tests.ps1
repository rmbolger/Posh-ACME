Describe "Update-PAOrder" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "ARI check with multiple orders in the pipeline" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { [pscustomobject]@{ alg = 'ES256'; location = 'https://acme.test/acme/acct/1' } }
            Mock -ModuleName Posh-ACME Get-PAServer { [pscustomobject]@{ renewalInfo = 'https://acme.test/acme/renewal-info'; DisableARI = $false } }
            Mock -ModuleName Posh-ACME Get-PACertificate { [pscustomobject]@{ ARIId = $MainDomain } }
            Mock -ModuleName Posh-ACME Invoke-RestMethod {
                if ($Uri -like '*/a.example.com') {
                    [pscustomobject]@{ suggestedWindow = [pscustomobject]@{
                        start = '2098-06-01T00:00:00Z'
                        end   = '2098-06-02T00:00:00Z'
                    }}
                } else {
                    throw 'ARI request failed'
                }
            }
            Mock -ModuleName Posh-ACME Write-Warning {}
        }

        It "Doesn't reuse the previous order's renewal window when the ARI request fails" {
            InModuleScope Posh-ACME {
                $orders = 'a.example.com','b.example.com' | ForEach-Object {
                    [pscustomobject]@{
                        PSTypeName  = 'PoshACME.PAOrder'
                        Name        = $_
                        MainDomain  = $_
                        Folder      = "TestDrive:\$_"
                        expires     = '2020-01-01T00:00:00Z'
                        CertExpires = '2099-01-01T00:00:00Z'
                        RenewAfter  = '2098-12-01T00:00:00Z'
                        PfxPass     = 'poshacme'
                    }
                }

                $orders | Update-PAOrder -ErrorAction SilentlyContinue

                $orders[0].RenewAfter | Should -Be '2098-06-01T00:00:00Z'
                $orders[1].RenewAfter | Should -Be '2098-12-01T00:00:00Z'
            }
        }
    }
}
