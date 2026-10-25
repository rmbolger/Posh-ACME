Describe 'Get-Sha3Hash' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'Hashes UTF-8 input with SHA3-256' {
        'abc' | Get-Sha3Hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
    }

    It 'Supports a custom digest size' {
        $hash = Get-Sha3Hash -InputString 'abc' -HashSize 512
        $hash.Length | Should -Be 128
    }
}
