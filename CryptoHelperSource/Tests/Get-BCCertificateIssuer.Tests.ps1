Describe 'Get-BCCertificateIssuer' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-CryptoHelperForTest -TestRoot $PSScriptRoot

        $chainPath = Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot/srvr1/acct1/example.com/chain0.cer'
        $certificates = [regex]::Matches((Get-Content $chainPath -Raw),
            '-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----',
            [Text.RegularExpressions.RegexOptions]::Singleline)
    }

    It 'Returns issuer common names from each certificate' {
        $certificates.Count | Should -Be 2
        $certificates[0].Value | Get-BCCertificateIssuer | Should -BeExactly '(STAGING) Pretend Pear X1'
        $certificates[1].Value | Get-BCCertificateIssuer | Should -BeExactly '(STAGING) Doctored Durian Root CA X3'
    }
}
