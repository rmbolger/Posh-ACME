Describe 'CryptoHelper module' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'Loads its BouncyCastle dependency in the expected context' {
        # For the ALC Load resolver by calling a dependent function
        'abc' | Get-Sha3Hash | Out-Null

        $assemblies = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -eq 'BouncyCastle.Cryptography'
        })
        if ($IsCoreCLR) {
            $isolated = @($assemblies | Where-Object {
                [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_).Name -eq 'CryptoHelper'
            })
            $isolated | Should -HaveCount 1
        } else {
            $assemblies | Should -Not -BeNullOrEmpty
        }
    }
}
