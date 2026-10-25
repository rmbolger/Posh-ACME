Describe 'Get-PACertificate' {
    BeforeAll {
        $previousHome = $env:POSHACME_HOME
        $configRoot = 'TestDrive:\PACertificateConfig'
        New-Item -Path $configRoot -ItemType Directory | Out-Null
        Get-ChildItem (Join-Path $PSScriptRoot 'TestFiles/ConfigRoot') |
            Copy-Item -Destination $configRoot -Recurse
        $env:POSHACME_HOME = $configRoot
        Import-Module (Join-Path $PSScriptRoot '../Posh-ACME/Posh-ACME.psd1') -Force
    }

    AfterAll {
        Remove-Module Posh-ACME -ErrorAction Ignore
        $env:POSHACME_HOME = $previousHome
    }

    It 'Builds certificate details using CryptoHelper' {
        $certificate = Get-PACertificate -MainDomain 'example.com'
        $certificate.Subject | Should -BeExactly 'CN=example.com'
        $certificate.Thumbprint | Should -BeExactly '47D51C8D00859491824D57F50BB35DEE07D2E029'
        $certificate.ARIId | Should -BeExactly 'zLv6VMSCAzhtm2UPIvh5pkMrGZM.HLlxoKGfUSg'
        $certificate.Serial | Should -BeExactly '2069810438473732392'
        $certificate.AllSANs | Should -BeExactly @('example.com')
    }
}
