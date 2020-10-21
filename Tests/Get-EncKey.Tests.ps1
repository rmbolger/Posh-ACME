Describe "Get-EncKey" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        $keyPath = Join-Path 'TestDrive:' 'enc-key.txt'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
        Mock -ModuleName Posh-ACME Get-ConfigRoot { return 'TestDrive:\' }
        Remove-Item $keyPath -EA Ignore
    }

    Context "PathOnly switch" {
        It "Should return the correct path" {
            InModuleScope Posh-ACME {
                Get-EncKey -PathOnly
            } | Should -Be $keyPath
        }
    }

    Context "No existing key file" {
        It "Behaves appropriately" {
            InModuleScope Posh-ACME {
                { Get-EncKey } | Should -Not -Throw
                Get-EncKey | Should -BeNullOrEmpty
            }
        }
    }

    Context "Invalid key file" {

        BeforeAll {
            'invalid encoding$' | Out-File $keyPath
            Mock Write-Warning {}
        }

        It "Returns null" {
            InModuleScope Posh-ACME {
                Get-EncKey | Should -BeNullOrEmpty
            }
            Test-Path $keyPath | Should -BeFalse
        }
    }

    Context "Key too small" {

        BeforeAll {
            Mock Write-Warning {}
        }

        It "Returns null" {
            InModuleScope Posh-ACME {
                ConvertTo-Base64Url -Bytes (1..31) | Out-File 'TestDrive:\enc-key.txt'
                Get-EncKey | Should -BeNullOrEmpty
            }
            Test-Path $keyPath | Should -BeFalse
        }
    }

    Context "Key too big" {

        BeforeAll {
            Mock Write-Warning {}
        }

        It "Returns null" {
            InModuleScope Posh-ACME {
                ConvertTo-Base64Url -Bytes (1..33) | Out-File 'TestDrive:\enc-key.txt'
                Get-EncKey | Should -BeNullOrEmpty
            }
            Test-Path $keyPath | Should -BeFalse
        }
    }

    Context "Key has extra whitespace/line feeds" {
        It "Behaves appropriately" {
            InModuleScope Posh-ACME {
                $keyEncoded = ConvertTo-Base64Url -Bytes ([byte[]](1..32))
                "`t$keyEncoded   `n`n" | Out-File 'TestDrive:\enc-key.txt'
                { Get-EncKey } | Should -Not -Throw
                $key = Get-EncKey
                $key | Should -Be (1..32)
            }
        }
    }

    Context "Key is normal" {
        It "Behaves appropriately" {
            InModuleScope Posh-ACME {
                $keyEncoded = ConvertTo-Base64Url -Bytes ([byte[]](1..32))
                $keyEncoded | Out-File 'TestDrive:\enc-key.txt'
                { Get-EncKey } | Should -Not -Throw
                $key = Get-EncKey
                $key | Should -Be (1..32)
            }
        }
    }
}
