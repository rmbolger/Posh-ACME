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
        }

        It "Returns the certificate for the order it was given" {
            # the current order is 'example.com', so use a different one
            $order = Get-PAOrder -Name 'altname'
            $order | Add-Member 'status' 'valid' -Force
            $order | Add-Member 'certificate' 'https://acme.test/acme/cert/44444' -Force
            $certFile = Join-Path $order.Folder 'cert.cer'
            Copy-Item (Join-Path $PSScriptRoot 'TestFiles/ConfigRoot/srvr1/acct1/example.com/cert.cer') $certFile

            $certDetail = InModuleScope Posh-ACME -Parameters @{ CertFile = $certFile } {
                Get-CertDetail -Pem (Get-Content $CertFile -Raw)
            }
            $expectedExpires = $certDetail.NotAfter.ToUniversalTime()
            $lifetime = $certDetail.NotAfter.ToUniversalTime() - $certDetail.NotBefore.ToUniversalTime()
            $renewHours = [Math]::Min(720, ($lifetime.TotalHours / 3))
            $expectedRenewAfter = $expectedExpires.AddHours(-$renewHours)

            Mock -ModuleName Posh-ACME Get-PACertificate { [pscustomobject]@{ Name = $Name } }

            $cert = $order | Complete-PAOrder

            $cert.Name | Should -BeExactly 'altname'
            $order.CertExpires | Should -BeExactly $expectedExpires.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
            $order.RenewAfter | Should -BeExactly $expectedRenewAfter.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
            Should -Invoke Get-PACertificate -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'altname'
            }
        }
    }
}
