Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "New-EncKey" {

    InModuleScope Posh-ACME {

        $keyPath = 'TestDrive:\enc-key.txt'
        Mock Get-EncKey { return $keyPath } -ParameterFilter { $PathOnly }

        Context "Existing key file" {

            'fake key contents' | Out-File $keyPath

            It "Throws an exception" {
                { New-EncKey } | Should -Throw
            }

            Remove-Item $keyPath -Force

        }

        Context "No existing key file" {

            It "Does not throw" {
                { New-EncKey } | Should -Not -Throw
            }

            It "Should create key file" {
                Test-Path $keyPath -PathType Leaf | Should -BeTrue
            }

            $keyEncoded = Get-Content $keyPath

            It "File should be decode'able" {
                { $keyEncoded | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw
            }

            It "Key should be 32 bytes" {
                $key = $keyEncoded | ConvertFrom-Base64Url -AsByteArray
                $key[0] | Should -BeOfType [byte]
                $key | Should -HaveCount 32
            }

        }

    }
}
