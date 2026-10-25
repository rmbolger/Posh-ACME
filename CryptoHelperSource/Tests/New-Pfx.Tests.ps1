Describe 'New-Pfx' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-CryptoHelperForTest -TestRoot $PSScriptRoot

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

    It 'Supports modern encryption and DER encoding options' {
        $pfx = New-Pfx -CertificatePem $certificatePem -PrivateKeyPem $privateKeyPem `
            -Password 'test-password' -UseModernPfxEncryption -UsePfxDerEncoding
        $pfx.Length | Should -BeGreaterThan 0
    }
}
