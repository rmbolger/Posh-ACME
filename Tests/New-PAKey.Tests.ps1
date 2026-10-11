Describe "New-PAKey" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

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
                $result.Key         | Should -BeOfType [Security.Cryptography.RSA]
                $result.Key.KeySize | Should -BeExactly 2048
                $result.KeyLength   | Should -BeExactly '2048'
            }
        }

        It "Generates 3072 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '3072'
                $result.Key         | Should -BeOfType [Security.Cryptography.RSA]
                $result.Key.KeySize | Should -BeExactly 3072
                $result.KeyLength   | Should -BeExactly '3072'
            }
        }

        It "Generates 4096 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '4096'
                $result.Key         | Should -BeOfType [Security.Cryptography.RSA]
                $result.Key.KeySize | Should -BeExactly 4096
                $result.KeyLength   | Should -BeExactly '4096'
            }
        }

        It "Generates 2176 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey '2176'
                $result.Key         | Should -BeOfType [Security.Cryptography.RSA]
                $result.Key.KeySize | Should -BeExactly 2176
                $result.KeyLength   | Should -BeExactly '2176'
            }
        }
    }

    Context "ECC" {

        It "Generates ec-256 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey 'ec-256'
                $result.Key         | Should -BeOfType [Security.Cryptography.ECDsa]
                $result.Key.KeySize | Should -BeExactly 256
                $result.KeyLength   | Should -BeExactly 'ec-256'
            }
        }

        It "Generates ec-384 key" {
            InModuleScope Posh-ACME {
                $result = New-PAKey 'ec-384'
                $result.Key         | Should -BeOfType [Security.Cryptography.ECDsa]
                $result.Key.KeySize | Should -BeExactly 384
                $result.KeyLength   | Should -BeExactly 'ec-384'
            }
        }
    }

    Context "Output object" {

        It "Includes key JWKs and the public JWK thumbprint" {
            InModuleScope Posh-ACME {
                $result = New-PAKey 'ec-256'

                $result.PSObject.Properties.Name | Should -Contain 'Key'
                $result.PSObject.Properties.Name | Should -Contain 'KeyLength'
                $result.PSObject.Properties.Name | Should -Contain 'JwkKey'
                $result.PSObject.Properties.Name | Should -Contain 'JwkPubKey'
                $result.PSObject.Properties.Name | Should -Contain 'JwkThumbprint'

                $privateJwk = $result.JwkKey
                $publicJwk = $result.JwkPubKey
                $privateJwk.kty | Should -BeExactly 'EC'
                $publicJwk.kty | Should -BeExactly 'EC'
                $privateJwk.PSObject.Properties.Name | Should -Contain 'd'
                $publicJwk.PSObject.Properties.Name | Should -Not -Contain 'd'

                $sha256 = [Security.Cryptography.SHA256]::Create()
                $publicJwkJson = $publicJwk | ConvertTo-Json -Depth 5 -Compress
                $expectedThumbprint = ConvertTo-Base64Url ($sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($publicJwkJson)))
                $result.JwkThumbprint | Should -BeExactly $expectedThumbprint
            }
        }

        It "Returns the imported key and derives its KeyLength" {
            $keyFile = Join-Path $PSScriptRoot 'TestFiles\ConfigRoot\srvr1\acct1\example.com\cert.key'
            $module = Get-Module Posh-ACME
            $result = & $module { param($path) New-PAKey -KeyFile $path } $keyFile

            $result.Key | Should -BeOfType [Security.Cryptography.RSA]
            $result.KeyLength | Should -BeExactly '2048'
            $result.JwkPubKey.kty | Should -BeExactly 'RSA'
            $result.JwkThumbprint | Should -Not -BeNullOrEmpty
        }
    }
}
