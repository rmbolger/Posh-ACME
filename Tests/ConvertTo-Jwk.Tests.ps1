Describe "ConvertTo-Jwk" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')

        # create sample keys
        $rsa2048 = [Security.Cryptography.RSACryptoServiceProvider]::new(2048)
        $rsa3072 = [Security.Cryptography.RSACryptoServiceProvider]::new(3072)
        $rsa4096 = [Security.Cryptography.RSACryptoServiceProvider]::new(4096)
        $ec256 = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7'))
        $ec384 = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.34'))
        $ec521 = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.35'))
    }

    Context "Bad Input" {
        It "Should throw" {
            InModuleScope Posh-ACME {
                { ConvertTo-Jwk 'asdf' } | Should -Throw
                { ConvertTo-Jwk $null }  | Should -Throw
                { ConvertTo-Jwk 1234 }   | Should -Throw
            }
        }
    }

    Context "RSA 2048 Pub/Priv" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData { $rsa2048 }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                $result.d   | Should -BeExactly (ConvertTo-Base64Url $keyParam.D)
                $result.p   | Should -BeExactly (ConvertTo-Base64Url $keyParam.P)
                $result.q   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q)
                $result.dp  | Should -BeExactly (ConvertTo-Base64Url $keyParam.DP)
                $result.dq  | Should -BeExactly (ConvertTo-Base64Url $keyParam.DQ)
                $result.qi  | Should -BeExactly (ConvertTo-Base64Url $keyParam.InverseQ)
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-AsJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It "Converts Properly (-AsPrettyJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsPrettyJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsPrettyJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw

                # pretty means multiple lines
                $result.Split([Environment]::NewLine).Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "RSA 2048 Public" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData {
                # return a public-only RSA 2048 key
                $pubkey = [Security.Cryptography.RSACryptoServiceProvider]::new()
                $pubkey.ImportParameters($rsa2048.ExportParameters($false))
                return $pubkey
            }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }
    }

    Context "RSA 3072 Pub/Priv" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData { $rsa3072 }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                $result.d   | Should -BeExactly (ConvertTo-Base64Url $keyParam.D)
                $result.p   | Should -BeExactly (ConvertTo-Base64Url $keyParam.P)
                $result.q   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q)
                $result.dp  | Should -BeExactly (ConvertTo-Base64Url $keyParam.DP)
                $result.dq  | Should -BeExactly (ConvertTo-Base64Url $keyParam.DQ)
                $result.qi  | Should -BeExactly (ConvertTo-Base64Url $keyParam.InverseQ)
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-AsJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It "Converts Properly (-AsPrettyJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsPrettyJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsPrettyJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw

                # pretty means multiple lines
                $result.Split([Environment]::NewLine).Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "RSA 3072 Public" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData {
                # return a public-only RSA 3072 key
                $pubkey = [Security.Cryptography.RSACryptoServiceProvider]::new()
                $pubkey.ImportParameters($rsa3072.ExportParameters($false))
                return $pubkey
            }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }
    }

    Context "RSA 4096 Pub/Priv" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData { $rsa4096 }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                $result.d   | Should -BeExactly (ConvertTo-Base64Url $keyParam.D)
                $result.p   | Should -BeExactly (ConvertTo-Base64Url $keyParam.P)
                $result.q   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q)
                $result.dp  | Should -BeExactly (ConvertTo-Base64Url $keyParam.DP)
                $result.dq  | Should -BeExactly (ConvertTo-Base64Url $keyParam.DQ)
                $result.qi  | Should -BeExactly (ConvertTo-Base64Url $keyParam.InverseQ)
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-AsJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It "Converts Properly (-AsPrettyJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsPrettyJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsPrettyJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw

                # pretty means multiple lines
                $result.Split([Environment]::NewLine).Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "RSA 4096 Public" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData {
                # return a public-only RSA 4096 key
                $pubkey = [Security.Cryptography.RSACryptoServiceProvider]::new()
                $pubkey.ImportParameters($rsa4096.ExportParameters($false))
                return $pubkey
            }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'RSA'
                $result.e   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Exponent)
                $result.n   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Modulus)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'p'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'q'  | Should -Not -BeIn $result.PSObject.Properties.Name
                'dp' | Should -Not -BeIn $result.PSObject.Properties.Name
                'dq' | Should -Not -BeIn $result.PSObject.Properties.Name
                'qi' | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }
    }

    Context "EC P-256 Pub/Priv" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData { $ec256 }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-256'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                $result.d   | Should -BeExactly (ConvertTo-Base64Url $keyParam.D)
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-256'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-AsJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It "Converts Properly (-AsPrettyJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsPrettyJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsPrettyJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw

                # pretty means multiple lines
                $result.Split([Environment]::NewLine).Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "EC P-256 Public" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData {
                # return a public-only EC P-256 key
                $pubkey = [Security.Cryptography.ECDsa]::Create()
                $pubkey.ImportParameters($ec256.ExportParameters($false))
                return $pubkey
            }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-256'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-256'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }
    }

    Context "EC P-384 Pub/Priv" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData { $ec384 }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-384'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                $result.d   | Should -BeExactly (ConvertTo-Base64Url $keyParam.D)
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-384'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-AsJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It "Converts Properly (-AsPrettyJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsPrettyJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsPrettyJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw

                # pretty means multiple lines
                $result.Split([Environment]::NewLine).Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "EC P-384 Public" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData {
                # return a public-only EC P-384 key
                $pubkey = [Security.Cryptography.ECDsa]::Create()
                $pubkey.ImportParameters($ec384.ExportParameters($false))
                return $pubkey
            }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-384'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-384'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }
    }

    Context "EC P-521 Pub/Priv" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData { $ec521 }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-521'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                $result.d   | Should -BeExactly (ConvertTo-Base64Url $keyParam.D)
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($true)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-521'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-AsJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It "Converts Properly (-AsPrettyJson)" {
            InModuleScope Posh-ACME {
                $keypair = TestData

                # other tests already take care of the key conversion specifics
                # so here we just care about making sure it's parseable JSON

                { ConvertTo-Jwk $keypair -AsPrettyJson } | Should -Not -Throw
                $result = ConvertTo-Jwk $keypair -AsPrettyJson
                $result | Should -BeOfType [string]
                { $result | ConvertFrom-Json } | Should -Not -Throw

                # pretty means multiple lines
                $result.Split([Environment]::NewLine).Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "EC P-521 Public" {

        BeforeAll {
            Mock -ModuleName Posh-ACME TestData {
                # return a public-only EC P-521 key
                $pubkey = [Security.Cryptography.ECDsa]::Create()
                $pubkey.ImportParameters($ec521.ExportParameters($false))
                return $pubkey
            }
        }

        It "Converts Properly (no params)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-521'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }

        It "Converts Properly (-PublicOnly)" {
            InModuleScope Posh-ACME {
                $keypair = TestData
                $keyParam = $keypair.ExportParameters($false)

                { ConvertTo-Jwk $keypair -PublicOnly } | Should -Not -Throw

                $result = ConvertTo-Jwk $keypair -PublicOnly

                $result.kty | Should -BeExactly 'EC'
                $result.crv | Should -BeExactly 'P-521'
                $result.x   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.X)
                $result.y   | Should -BeExactly (ConvertTo-Base64Url $keyParam.Q.Y)
                'd'  | Should -Not -BeIn $result.PSObject.Properties.Name
            }
        }
    }

}
