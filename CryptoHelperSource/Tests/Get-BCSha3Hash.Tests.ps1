Describe 'Get-BCSha3Hash' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-CryptoHelperForTest -TestRoot $PSScriptRoot
    }

    It 'Hashes UTF-8 input with SHA3-256' {
        'abc' | Get-BCSha3Hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
    }
}
