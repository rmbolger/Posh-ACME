Describe 'New-CsrHelper' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'Generates <KeyLength> private keys and signed CSRs' -TestCases @(
        @{ KeyLength = '2048'; PemHeader = '-----BEGIN PRIVATE KEY-----' }
        @{ KeyLength = 'ec-256'; PemHeader = '-----BEGIN EC PRIVATE KEY-----' }
    ) {
        $identifiers = @(
            @{ type = 'dns'; value = 'example.com' }
            @{ type = 'ip'; value = '192.0.2.1' }
        )

        $result = New-CsrHelper -KeyLength $KeyLength -Subject 'CN=example.com' `
            -Identifiers $identifiers -OCSPMustStaple $true
        $details = $result.RequestPem | Get-CsrDetail

        $result.PrivateKeyPem | Should -Match "^$([regex]::Escape($PemHeader))"
        $result.Base64Url | Should -Not -BeNullOrEmpty
        $details.KeyLength | Should -BeExactly $KeyLength
        $details.Domain | Should -BeExactly @('example.com', '192.0.2.1')
        $details.OCSPMustStaple | Should -BeTrue
    }

    It 'Rejects unsupported EC key sizes' {
        { New-CsrHelper -KeyLength 'ec-192' -Subject 'CN=example.com' } |
            Should -Throw '*Unsupported EC key size*'
    }

    It 'Rejects invalid private-key PEM' {
        { New-CsrHelper -KeyLength 'ec-256' -Subject 'CN=example.com' -PrivateKeyPem 'not a PEM key' } |
            Should -Throw '*supported RSA or EC private key*'
    }
}
