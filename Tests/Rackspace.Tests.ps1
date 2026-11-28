Describe "Connect-RackspaceDns" {

    BeforeAll {
        . (Join-Path $PSScriptRoot '..\Posh-ACME\Plugins\Rackspace.ps1')
        . (Join-Path $PSScriptRoot '..\Posh-ACME\Private\MockWrappers.ps1')
        . (Join-Path $PSScriptRoot '..\Posh-ACME\Private\Repair-ISODate.ps1')
        $script:UseBasic = @{UseBasicParsing = $true}
        Mock Invoke-RestMethod {
            [pscustomobject]@{ access = [pscustomobject]@{
                token = [pscustomobject]@{ id = 'TokenSentinel'; expires = '2099-01-01T00:00:00Z' }
                serviceCatalog = @([pscustomobject]@{
                    name = 'cloudDNS'
                    endpoints = @([pscustomobject]@{ publicURL = 'https://dns.example.invalid/v1.0/1' })
                })
            } }
        }
    }

    It "Doesn't write the session token to the debug stream" {
        $script:RSAuth = $null
        $DebugPreference = 'Continue'
        $log = Connect-RackspaceDns 'user' (ConvertTo-SecureString 'key' -AsPlainText -Force) 5>&1 | Out-String
        $log | Should -Not -Match 'TokenSentinel'
        $script:RSAuth.token | Should -Be 'TokenSentinel'
    }
}
