Describe "New-EncKey" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        $keyPath = 'TestDrive:\enc-key.txt'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
        Mock -ModuleName Posh-ACME Get-ConfigRoot { return 'TestDrive:\' }
        Mock -ModuleName Posh-ACME Get-EncKey { return $keyPath } -ParameterFilter { $PathOnly }
        Remove-Item $keyPath -EA Ignore
    }

    Context "Existing key file" {

        BeforeAll {
            'fake key contents' | Out-File $keyPath
        }

        It "Throws an exception" {
            InModuleScope Posh-ACME {
                { New-EncKey } | Should -Throw
            }
        }
    }

    Context "No existing key file" {
        It "Creates a key" {
            InModuleScope Posh-ACME {
                { New-EncKey } | Should -Not -Throw
            }
            Test-Path $keyPath -PathType Leaf | Should -BeTrue

            InModuleScope Posh-ACME {
                $keyEncoded = Get-Content 'TestDrive:\enc-key.txt'
                { $keyEncoded | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw

                $key = $keyEncoded | ConvertFrom-Base64Url -AsByteArray
                $key[0] | Should -BeOfType [byte]
                $key | Should -HaveCount 32
            }
        }
    }

}
