BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
}

Describe "New-PAKey" {

    Context "Parameter validation" {

        It "Should validate parameters" {
            InModuleScope Posh-ACME {
                { New-PAKey }                     | Should -Not -Throw
                # invalid keylength
                { New-PAKey -KeyLength $null }    | Should -Throw
                { New-PAKey -KeyLength '' }       | Should -Throw
                { New-PAKey -KeyLength 'asdf' }   | Should -Throw
                # keylength out of range
                { New-PAKey -KeyLength '1024' }   | Should -Throw
                { New-PAKey -KeyLength '8192' }   | Should -Throw
                { New-PAKey -KeyLength '3000' }   | Should -Throw
                { New-PAKey -KeyLength 'ec-128' } | Should -Throw
                { New-PAKey -KeyLength 'ec-522' } | Should -Throw
                { New-PAKey -KeyLength 'ec-' }    | Should -Throw
            }
        }
    }

    Context "RSA" {

        It "Generates 2048 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '2048'
                $result         | Should -BeOfType [Security.Cryptography.RSA]
                $result.KeySize | Should -BeExactly 2048
            }
        }

        It "Generates 3072 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '3072'
                $result         | Should -BeOfType [Security.Cryptography.RSA]
                $result.KeySize | Should -BeExactly 3072
            }
        }

        It "Generates 4096 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '4096'
                $result         | Should -BeOfType [Security.Cryptography.RSA]
                $result.KeySize | Should -BeExactly 4096
            }
        }

        It "Generates 2176 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '2176'
                $result         | Should -BeOfType [Security.Cryptography.RSA]
                $result.KeySize | Should -BeExactly 2176
            }
        }
    }

    Context "ECC" {

        It "Generates ec-256 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey 'ec-256'
                $result         | Should -BeOfType [Security.Cryptography.ECDsa]
                $result.KeySize | Should -BeExactly 256
            }
        }

        It "Generates ec-384 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey 'ec-384'
                $result         | Should -BeOfType [Security.Cryptography.ECDsa]
                $result.KeySize | Should -BeExactly 384
            }
        }
    }
}
