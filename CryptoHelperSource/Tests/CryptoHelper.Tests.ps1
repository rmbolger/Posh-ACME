Describe 'CryptoHelper module' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-CryptoHelperForTest -TestRoot $PSScriptRoot
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
    }

    It 'Exports its cmdlets after force re-import' {
        Import-Module $modulePath -Force -ErrorAction Stop
        $commands = (Get-Module CryptoHelper).ExportedCmdlets.Keys
        $commands | Should -Contain 'Get-Sha3Hash'
        $commands | Should -Contain 'Get-CertDetail'
        $commands | Should -Contain 'Get-CsrDetail'
        $commands | Should -Contain 'New-CsrHelper'
        $commands | Should -Contain 'ConvertFrom-PemPrivateKey'
        'abc' | Get-Sha3Hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
    }

    It 'Loads its BouncyCastle dependency in the expected context' {
        $assemblies = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -in 'BouncyCastle.Cryptography', 'BouncyCastle.Crypto', 'BC.Crypto'
        })
        if ($IsCoreCLR) {
            $isolated = @($assemblies | Where-Object {
                [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_).Name -eq 'CryptoHelper'
            })
            $default = @($assemblies | Where-Object {
                [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_) -eq [Runtime.Loader.AssemblyLoadContext]::Default
            })
            $isolated | Should -HaveCount 1
            $default | Should -HaveCount 1
        } else {
            @($assemblies | Where-Object { $_.GetName().Name -eq 'BouncyCastle.Cryptography' }) | Should -HaveCount 1
        }
    }
}
