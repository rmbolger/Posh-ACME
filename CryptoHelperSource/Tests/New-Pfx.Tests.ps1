Describe 'New-Pfx' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop

        $fixtureRoot = Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot/srvr1/acct1/example.com'
        $certificatePem = Get-Content (Join-Path $fixtureRoot 'cert.cer') -Raw
        $privateKeyPem = Get-Content (Join-Path $fixtureRoot 'cert.key') -Raw
        $chainPem = [regex]::Matches((Get-Content (Join-Path $fixtureRoot 'chain0.cer') -Raw),
            '-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----',
            [Text.RegularExpressions.RegexOptions]::Singleline)
    }

    It 'Preserves leaf-first certificate order in the PFX' -Skip:(!$IsCoreCLR) {
        $pfx = New-Pfx -CertificatePem $certificatePem -PrivateKeyPem $privateKeyPem `
            -ChainPem @($chainPem | ForEach-Object Value) -Password 'test-password'
        $bytesRead = 0
        $pfxInfo = [System.Security.Cryptography.Pkcs.Pkcs12Info]::Decode(
            $pfx, [ref]$bytesRead, $true)

        $certificateDetails = foreach ($contentInfo in $pfxInfo.AuthenticatedSafe) {
            $safeContents = $contentInfo
            if ($contentInfo.ConfidentialityMode -eq [System.Security.Cryptography.Pkcs.Pkcs12ConfidentialityMode]::Password) {
                $contentInfo.Decrypt('test-password')
            }
            foreach ($bag in $safeContents.GetBags()) {
                if ($bag -is [System.Security.Cryptography.Pkcs.Pkcs12CertBag]) {
                    [regex]::Match($bag.GetCertificate().Subject, 'CN=([^,]+)').Groups[1].Value
                }
            }
        }

        $certificateDetails | Should -Be @(
            'example.com',
            '(STAGING) Artificial Apricot R3',
            '(STAGING) Pretend Pear X1'
        )
    }

    It 'Uses legacy RC2 encryption and BER encoding by default' {
        $pfx = New-Pfx -CertificatePem $certificatePem -PrivateKeyPem $privateKeyPem `
            -Password 'test-password'
        $details = Get-PfxEncodingDetail -Pfx $pfx

        $details.KeyEncryptionAlgorithm | Should -BeExactly '1.2.840.113549.1.12.1.6'
        $details.KeyEncryptionScheme | Should -BeNullOrEmpty
        $details.KeyEncryptionPrf | Should -BeNullOrEmpty
        $details.IsDerEncoded | Should -BeFalse
    }

    It 'Uses AES-256-CBC with HMAC-SHA256 when modern encryption is requested' {
        $pfx = New-Pfx -CertificatePem $certificatePem -PrivateKeyPem $privateKeyPem `
            -Password 'test-password' -UseModernPfxEncryption
        $details = Get-PfxEncodingDetail -Pfx $pfx

        $details.KeyEncryptionAlgorithm | Should -BeExactly '1.2.840.113549.1.5.13'
        $details.KeyEncryptionScheme | Should -BeExactly '2.16.840.1.101.3.4.1.42'
        $details.KeyEncryptionPrf | Should -BeExactly '1.2.840.113549.2.9'
        $details.IsDerEncoded | Should -BeFalse
    }

    It 'Uses DER encoding when requested' {
        $pfx = New-Pfx -CertificatePem $certificatePem -PrivateKeyPem $privateKeyPem `
            -Password 'test-password' -UsePfxDerEncoding
        $details = Get-PfxEncodingDetail -Pfx $pfx

        $details.KeyEncryptionAlgorithm | Should -BeExactly '1.2.840.113549.1.12.1.6'
        $details.IsDerEncoded | Should -BeTrue
    }
}
