Describe 'Get-BCCertificateDetails' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-CryptoHelperForTest -TestRoot $PSScriptRoot
        $certPath = Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot/srvr1/acct1/example.com/cert.cer'
    }

    It 'Returns certificate details as PowerShell-friendly values' {
        $details = Get-Content $certPath -Raw | Get-BCCertificateDetails
        $details.Subject | Should -BeExactly 'CN=example.com'
        $details.NotBefore | Should -BeOfType [datetime]
        $details.NotAfter | Should -BeOfType [datetime]
        $details.Thumbprint | Should -BeExactly '47D51C8D00859491824D57F50BB35DEE07D2E029'
        $details.ARIId | Should -BeExactly 'zLv6VMSCAzhtm2UPIvh5pkMrGZM.HLlxoKGfUSg'
        $details.Serial | Should -BeExactly '2069810438473732392'
        $details.AllSANs | Should -BeExactly @('example.com')
    }
}
