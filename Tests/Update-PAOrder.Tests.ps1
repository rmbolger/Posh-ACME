Describe "Update-PAOrder" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
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

    Context "ARI window validation during renewal" {
        BeforeAll {
            Mock -ModuleName Posh-ACME Get-PAAccount { [pscustomobject]@{} }
            Mock -ModuleName Posh-ACME Get-PAServer { [pscustomobject]@{ renewalInfo = 'https://acme.test/renewal-info' } }
            Mock -ModuleName Posh-ACME Get-PACertificate { [pscustomobject]@{ ARIId = 'test-cert' } }
            Mock -ModuleName Posh-ACME Get-DateTimeOffsetNow { [DateTimeOffset]'2026-01-01T00:00:00Z' }
            Mock -ModuleName Posh-ACME Get-PAPluginArgs { @{} }
            Mock -ModuleName Posh-ACME New-PACertificate {}
        }

        It "Keeps the expected renewal time for <Case>" -ForEach @(
            @{ Case = 'equal endpoints'; Start = '2025-12-01T00:00:00Z'; End = '2025-11-30T19:00:00-05:00' }
            @{ Case = 'reversed endpoints'; Start = '2025-12-02T00:00:00Z'; End = '2025-12-01T00:00:00Z' }
            @{ Case = 'missing end'; Start = '2025-12-01T00:00:00Z'; End = $null }
            @{ Case = 'malformed end'; Start = '2025-12-01T00:00:00Z'; End = 'invalid' }
            @{ Case = 'malformed start'; Start = 'invalid'; End = '2026-01-02T00:00:00Z' }
            @{ Case = 'date without a time'; Start = '2025-12-01'; End = '2026-01-02T00:00:00Z' }
            @{ Case = 'deserialized start without a time zone'; Start = '2025-12-01T00:00:00'; End = '2026-01-02T00:00:00Z'; Deserialize = $true }
            @{ Case = 'deserialized end without a time zone'; Start = '2025-12-01T00:00:00Z'; End = '2026-01-02T00:00:00'; Deserialize = $true }
            @{ Case = 'valid future window'; Start = '2026-01-10T00:00:00.1Z'; End = '2026-01-10T00:00:00.9Z'; Expected = '2026-01-10T00:00:00.1Z' }
            @{ Case = 'deserialized dates'; Start = ([DateTimeOffset]'2026-01-10T00:00:00.1Z').LocalDateTime; End = ([DateTimeOffset]'2026-01-10T00:00:00.9Z').UtcDateTime; Expected = '2026-01-10T00:00:00.1000000Z' }
        ) {
            $testOrder = [pscustomobject]@{
                PSTypeName  = 'PoshACME.PAOrder'
                Name        = 'example.com'
                MainDomain  = 'example.com'
                Folder      = 'TestDrive:\ari-order'
                expires     = '2025-12-01T00:00:00Z'
                CertExpires = '2026-03-01T00:00:00Z'
                RenewAfter  = '2026-02-01T00:00:00Z'
                Plugin      = 'Manual'
                KeyLength   = '2048'
                PfxPass     = 'poshacme'
            }
            if (-not $Expected) { $Expected = $testOrder.RenewAfter }
            $ariResponse = [pscustomobject]@{ suggestedWindow = [pscustomobject]@{ start = $Start; end = $End } }
            if ($Deserialize) { $ariResponse = $ariResponse | ConvertTo-Json | ConvertFrom-Json }
            Mock -ModuleName Posh-ACME Get-PAOrder { $testOrder }
            Mock -ModuleName Posh-ACME Invoke-RestMethod { $ariResponse }

            Submit-Renewal -NoSkipManualDns -WarningAction SilentlyContinue -ErrorAction Stop

            Should -Invoke New-PACertificate -ModuleName Posh-ACME -Times 0 -Exactly
            $testOrder.RenewAfter | Should -Be $Expected
            $savedOrder = Get-Content (Join-Path $testOrder.Folder 'order.json') -Raw | ConvertFrom-Json
            [DateTimeOffset]$savedOrder.RenewAfter | Should -Be ([DateTimeOffset]$Expected)
        }
    }
}
