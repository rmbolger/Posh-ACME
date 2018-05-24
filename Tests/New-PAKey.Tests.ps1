Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "New-PAKey" {
    InModuleScope Posh-ACME {

        Context "Parameter validation" {

            It "should not throw with no params" {
                { New-PAKey } | Should -Not -Throw
            }
            It "should throw with null KeyLength" {
                { New-PAKey $null } | Should -Throw
            }
            It "should throw with empty KeyLenght" {
                { New-PAKey '' } | Should -Throw
            }
            It "should throw with invalid KeyLength" {
                { New-PAKey 'asdf' } | Should -Throw
            }
            It "should throw with RSA length out of range #1" {
                { New-PAKey '1024' } | Should -Throw
            }
            It "should throw with RSA length out of range #2" {
                { New-PAKey '8192' } | Should -Throw
            }
            It "should throw with RSA length out of range #3" {
                { New-PAKey '3000' } | Should -Throw
            }
            It "should throw with invalid EC length #1" {
                { New-PAKey 'ec-128' } | Should -Throw
            }
            It "should throw with invalid EC length #2" {
                { New-PAKey 'ec-522' } | Should -Throw
            }
            It "should throw with invalid EC length #3" {
                { New-PAKey 'ec-' } | Should -Throw
            }

        }

        Context "RSA Keys" {
            $result = New-PAKey '2048'
            It "2048 should be RSA type" {
                $result | Should -BeOfType [Security.Cryptography.RSA]
            }
            It "2048 should have correct KeySize" {
                $result.KeySize | Should -BeExactly 2048
            }
            $result = New-PAKey '3072'
            It "3072 should be RSA type" {
                $result | Should -BeOfType [Security.Cryptography.RSA]
            }
            It "3072 should have correct KeySize" {
                $result.KeySize | Should -BeExactly 3072
            }
            $result = New-PAKey '4096'
            It "4096 should be RSA type" {
                $result | Should -BeOfType [Security.Cryptography.RSA]
            }
            It "4096 should have correct KeySize" {
                $result.KeySize | Should -BeExactly 4096
            }
        }

        Context "ECC Keys" {
            $result = New-PAKey 'ec-256'
            It "ec-256 should be ECDsa type" {
                $result | Should -BeOfType [Security.Cryptography.ECDsa]
            }
            It "ec-256 should have correct KeySize" {
                $result.KeySize | Should -BeExactly 256
            }
            $result = New-PAKey 'ec-384'
            It "ec-384 should be ECDsa type" {
                $result | Should -BeOfType [Security.Cryptography.ECDsa]
            }
            It "ec-384 should have correct KeySize" {
                $result.KeySize | Should -BeExactly 384
            }
        }
    }
}
