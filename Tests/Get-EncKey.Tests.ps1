Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "Get-EncKey" {

    InModuleScope Posh-ACME {

        $keyPath = 'TestDrive:\enc-key.txt'
        Mock Get-ConfigRoot { return 'TestDrive:\' }

        Context "PathOnly switch" {
            It "Should return the correct path" {
                Get-EncKey -PathOnly | Should -Be $keyPath
            }
        }

        Context "No existing key file" {
            It "Does not throw" {
                { Get-EncKey } | Should -Not -Throw
            }
            It "Returns null" {
                Get-EncKey | Should -BeNullOrEmpty
            }
        }

        Context "Invalid key file" {

            'invalid encoding$' | Out-File $keyPath

            It "Returns null" {
                Get-EncKey | Should -BeNullOrEmpty
            }
            It "Deletes the bad file" {
                Test-Path $keyPath | Should -BeFalse
            }

            Remove-Item $keyPath -Force -EA SilentlyContinue

        }

        Context "Key too small" {

            ConvertTo-Base64Url -Bytes (1..31) | Out-File $keyPath

            It "Returns null" {
                Get-EncKey | Should -BeNullOrEmpty
            }
            It "Deletes the bad file" {
                Test-Path $keyPath | Should -BeFalse
            }

            Remove-Item $keyPath -Force -EA SilentlyContinue

        }

        Context "Key too big" {

            ConvertTo-Base64Url -Bytes (1..33) | Out-File $keyPath

            It "Returns null" {
                Get-EncKey | Should -BeNullOrEmpty
            }
            It "Deletes the bad file" {
                Test-Path $keyPath | Should -BeFalse
            }

            Remove-Item $keyPath -Force -EA SilentlyContinue

        }

        Context "Key has extra whitespace/line feeds" {

            $keyEncoded = ConvertTo-Base64Url -Bytes ([byte[]](1..32))
            "`t$keyEncoded   `n`n" | Out-File $keyPath

            It "Does not throw" {
                { Get-EncKey } | Should -Not -Throw
            }
            It "Returns the correct key" {
                $key = Get-EncKey
                $key | Should -Be (1..32)
            }

        }

        Context "Key is normal" {

            $keyEncoded = ConvertTo-Base64Url -Bytes ([byte[]](1..32))
            $keyEncoded | Out-File $keyPath

            It "Does not throw" {
                { Get-EncKey } | Should -Not -Throw
            }
            It "Returns the correct key" {
                $key = Get-EncKey
                $key | Should -Be (1..32)
            }

        }

    }
}
