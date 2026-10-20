Describe 'Get-CertDetail' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-CryptoHelperForTest -TestRoot $PSScriptRoot

        $chainPath = Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot/srvr1/acct1/example.com/chain0.cer'
        $certificates = [regex]::Matches((Get-Content $chainPath -Raw),
            '-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----',
            [Text.RegularExpressions.RegexOptions]::Singleline)
        $certPath = Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot/srvr1/acct1/example.com/cert.cer'
    }

    It 'Returns issuer CNs and metadata as PowerShell-friendly values' {
        $details = Get-Content $certPath -Raw | Get-CertDetail
        $details.IssuerCNs | Should -BeExactly 'Pebble Intermediate CA 7e3436'
        $details.Subject | Should -BeExactly 'CN=example.com'
        $details.NotBefore | Should -BeOfType [datetime]
        $details.NotAfter | Should -BeOfType [datetime]
        $details.Thumbprint | Should -BeExactly '47D51C8D00859491824D57F50BB35DEE07D2E029'
        $details.ARIId | Should -BeExactly 'zLv6VMSCAzhtm2UPIvh5pkMrGZM.HLlxoKGfUSg'
        $details.Serial | Should -BeExactly '2069810438473732392'
        $details.AllSANs | Should -BeExactly @('example.com')
    }

    It 'Returns issuer CNs for every certificate in a chain' {
        $certificates.Count | Should -Be 2
        $first = $certificates[0].Value | Get-CertDetail
        $second = $certificates[1].Value | Get-CertDetail
        $first.IssuerCNs | Should -BeExactly '(STAGING) Pretend Pear X1'
        $second.IssuerCNs | Should -BeExactly '(STAGING) Doctored Durian Root CA X3'
    }
}
