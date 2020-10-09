Describe "New-Jws" {

    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "Key Validation" {
        It "Validates RSA Keys" {
            InModuleScope Posh-ACME {

                # invalid RSA sizes
                1024,8192 | %{
                    $keypair = [Security.Cryptography.RSACryptoServiceProvider]::new($_)
                    $header = [ordered]@{
                        alg   = 'RS256'
                        jwk   = $keypair | ConvertTo-Jwk -PublicOnly
                        nonce = 'fakenonce'
                        url   = 'https://example.com'
                    }
                    { New-Jws -Key $keypair -Header $header -Payload '' } | Should -Throw
                }

                # valid RSA sizes
                2048,2176,3072,4096 | %{
                    $keypair = [Security.Cryptography.RSACryptoServiceProvider]::new($_)
                    $header = [ordered]@{
                        alg   = 'RS256'
                        jwk   = $keypair | ConvertTo-Jwk -PublicOnly
                        nonce = 'fakenonce'
                        url   = 'https://example.com'
                    }
                    { New-Jws -Key $keypair -Header $header -Payload '' } | Should -Not -Throw
                }
            }
        }

        It "Validates EC Keys" {
            InModuleScope Posh-ACME {

                # invalid EC curves
                @(
                    [Security.Cryptography.ECCurve+NamedCurves]::nistP521
                ) | %{
                    $keypair = [Security.Cryptography.ECDsa]::Create($_)
                    $header = [ordered]@{
                        alg   = "ES$($keypair.KeySize)"
                        jwk   = $keypair | ConvertTo-Jwk -PublicOnly
                        nonce = 'fakenonce'
                        url   = 'https://example.com'
                    }
                    { New-Jws -Key $keypair -Header $header -Payload '' } | Should -Throw
                }

                # valid EC curves
                @(
                    [Security.Cryptography.ECCurve+NamedCurves]::nistP256
                    [Security.Cryptography.ECCurve+NamedCurves]::nistP384
                ) | %{
                    $keypair = [Security.Cryptography.ECDsa]::Create($_)
                    $header = [ordered]@{
                        alg   = "ES$($keypair.KeySize)"
                        jwk   = $keypair | ConvertTo-Jwk -PublicOnly
                        nonce = 'fakenonce'
                        url   = 'https://example.com'
                    }
                    { New-Jws -Key $keypair -Header $header -Payload '' } | Should -Not -Throw
                }
            }
        }
    }

    Context "Header validation" {
        It "Validates header parameters" {
            InModuleScope Posh-ACME {

                $rsaKey = [Security.Cryptography.RSACryptoServiceProvider]::new(2048)
                $rsaHeader = [ordered]@{
                    alg   = 'RS256'
                    jwk   = ($rsaKey | ConvertTo-Jwk -PublicOnly)
                    nonce = 'fakenonce'
                    url   ='https://example.com'
                }
                $ecKey = [Security.Cryptography.ECDsa]::Create(
                    [Security.Cryptography.ECCurve+NamedCurves]::nistP256
                )
                $ecHeader = [ordered]@{
                    alg   = 'ES256'
                    jwk   = ($ecKey | ConvertTo-Jwk -PublicOnly)
                    nonce = 'fakenonce'
                    url   = 'https://example.com'
                }
                $hmac = [Security.Cryptography.HMACSHA256]::new((1..64))
                $hmacHeader = [ordered]@{
                    alg = 'HS256'
                    kid = 'xxxxxxxxxxxx'
                    url = 'https://example.com'
                }

                # proper headers should not throw
                { New-Jws $rsaKey $rsaHeader '' } | Should -Not -Throw
                { New-Jws $ecKey $ecHeader '' }   | Should -Not -Throw

                # header mistakes should throw unless -NoHeaderValidation

                # RSA
                $rsaHeader.Remove('alg')
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.alg = 'fake'
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.alg = 'ES256'
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.alg = 'HS256'
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.alg = 'RS256'
                $rsaHeader.kid = 'xxxxxxxxxxxx'
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.Remove('kid')
                $rsaHeader.Remove('jwk')
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.kid = '     '
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.Remove('kid')
                $rsaHeader.jwk = '     '
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.jwk = ($rsaKey | ConvertTo-Jwk -PublicOnly)
                $rsaHeader.Remove('nonce')
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.nonce = '     '
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.nonce = 'fakenonce'
                $rsaHeader.Remove('url')
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.url = '     '
                { New-Jws $rsaKey $rsaHeader '' }                     | Should -Throw
                { New-Jws $rsaKey $rsaHeader '' -NoHeaderValidation } | Should -Not -Throw
                $rsaHeader.url = 'https://example.com'

                # EC
                $ecHeader.Remove('alg')
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.alg = 'fake'
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.alg = 'RS256'
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.alg = 'HS256'
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.alg = 'ES256'
                $ecHeader.kid = 'xxxxxxxxxxxx'
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.Remove('kid')
                $ecHeader.Remove('jwk')
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.kid = '     '
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.Remove('kid')
                $ecHeader.jwk = '     '
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.jwk = ($ecKey | ConvertTo-Jwk -PublicOnly)
                $ecHeader.Remove('nonce')
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.nonce = '     '
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.nonce = 'fakenonce'
                $ecHeader.Remove('url')
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.url = '     '
                { New-Jws $ecKey $ecHeader '' }                     | Should -Throw
                { New-Jws $ecKey $ecHeader '' -NoHeaderValidation } | Should -Not -Throw
                $ecHeader.url = 'https://example.com'

                # HMAC
                $hmacHeader.Remove('alg')
                { New-Jws $hmac $hmacHeader '' }                     | Should -Throw
                { New-Jws $hmac $hmacHeader '' -NoHeaderValidation } | Should -Not -Throw
                $hmacHeader.alg = 'fake'
                { New-Jws $hmac $hmacHeader '' }                     | Should -Throw
                { New-Jws $hmac $hmacHeader '' -NoHeaderValidation } | Should -Not -Throw
                $hmacHeader.alg = 'RS256'
                { New-Jws $hmac $hmacHeader '' }                     | Should -Throw
                { New-Jws $hmac $hmacHeader '' -NoHeaderValidation } | Should -Not -Throw
                $hmacHeader.alg = 'ES256'
                { New-Jws $hmac $hmacHeader '' }                     | Should -Throw
                { New-Jws $hmac $hmacHeader '' -NoHeaderValidation } | Should -Not -Throw
            }
        }
    }

    Context "RSA 2048" {
        It "Creates Valid JWS" {
            InModuleScope Posh-ACME {

                $keypair = [Security.Cryptography.RSACryptoServiceProvider]::new(2048)
                $origHeader = [ordered]@{
                    alg   = 'RS256'
                    jwk   = ($keypair | ConvertTo-Jwk -PublicOnly)
                    nonce = 'fakenonce'
                    url   ='https://example.com'
                }
                $origPayload = '{"mykey":"myvalue"}'

                $result = New-Jws $keypair $origHeader $origPayload
                { $result | ConvertFrom-Json } | Should -Not -Throw

                $jws = $result | ConvertFrom-Json
                { $jws.payload   | ConvertFrom-Base64Url }              | Should -Not -Throw
                { $jws.protected | ConvertFrom-Base64Url }              | Should -Not -Throw
                { $jws.signature | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw

                $payload = $jws.payload | ConvertFrom-Base64Url
                { $payload | ConvertFrom-Json } | Should -Not -Throw
                $payload | Should -BeExactly $origPayload

                $protected = $jws.protected | ConvertFrom-Base64Url
                { $protected | ConvertFrom-Json } | Should -Not -Throw

                $header = $protected | ConvertFrom-Json
                $header.alg   | Should -BeExactly $origHeader.alg
                $header.nonce | Should -BeExactly $origHeader.nonce
                $header.url   | Should -BeExactly $origHeader.url
                ($header.jwk | ConvertTo-Json -Compress) | Should -BeExactly ($origHeader.jwk | ConvertTo-Json -Compress)

                # verify the signature
                $sigBytes = $jws.signature | ConvertFrom-Base64Url -AsByteArray
                $dataBytes = [Text.Encoding]::ASCII.GetBytes("$($jws.protected).$($jws.payload)")
                $pubKey = ConvertFrom-Jwk ($header.jwk | ConvertTo-Json)
                $HashAlgo = [Security.Cryptography.HashAlgorithmName]::SHA256
                $PaddingType = [Security.Cryptography.RSASignaturePadding]::Pkcs1
                $pubKey.VerifyData($dataBytes,$sigBytes,$HashAlgo,$PaddingType) | Should -BeTrue
            }
        }
    }

    Context "EC P-256" {
        It "Creates Valid JWS" {
            InModuleScope Posh-ACME {

                $keypair = [Security.Cryptography.ECDsa]::Create(
                    [Security.Cryptography.ECCurve+NamedCurves]::nistP256
                )
                $origHeader = [ordered]@{
                    alg   = 'ES256'
                    jwk   = ($keypair | ConvertTo-Jwk -PublicOnly)
                    nonce = 'fakenonce'
                    url   = 'https://example.com'
                }
                $origPayload = '{"mykey":"myvalue"}'

                $result = New-Jws $keypair $origHeader $origPayload
                { $result | ConvertFrom-Json } | Should -Not -Throw

                $jws = $result | ConvertFrom-Json
                { $jws.payload   | ConvertFrom-Base64Url }              | Should -Not -Throw
                { $jws.protected | ConvertFrom-Base64Url }              | Should -Not -Throw
                { $jws.signature | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw

                $payload = $jws.payload | ConvertFrom-Base64Url
                { $payload | ConvertFrom-Json } | Should -Not -Throw
                $payload | Should -BeExactly $origPayload

                $protected = $jws.protected | ConvertFrom-Base64Url
                { $protected | ConvertFrom-Json } | Should -Not -Throw

                $header = $protected | ConvertFrom-Json
                $header.alg   | Should -BeExactly $origHeader.alg
                $header.nonce | Should -BeExactly $origHeader.nonce
                $header.url   | Should -BeExactly $origHeader.url
                ($header.jwk | ConvertTo-Json -Compress) | Should -BeExactly ($origHeader.jwk | ConvertTo-Json -Compress)

                # verify the signature
                $sigBytes = $jws.signature | ConvertFrom-Base64Url -AsByteArray
                $dataBytes = [Text.Encoding]::ASCII.GetBytes("$($jws.protected).$($jws.payload)")
                $HashAlgo = [Security.Cryptography.HashAlgorithmName]::SHA256
                $pubKey = ConvertFrom-Jwk ($header.jwk | ConvertTo-Json)
                $pubKey.VerifyData($dataBytes,$sigBytes,$HashAlgo) | Should -BeTrue
            }
        }
    }

    Context "HMAC256" {
        It "Creates Valid JWS" {
            InModuleScope Posh-ACME {

                $hmac = [Security.Cryptography.HMACSHA256]::new((1..64))
                $origHeader = [ordered]@{
                    alg = 'HS256'
                    kid = 'xxxxxxxxxxxx'
                    url = 'https://example.com'
                }
                $origPayload = '{"mykey":"myvalue"}'

                $result = New-Jws $hmac $origHeader $origPayload
                { $result | ConvertFrom-Json } | Should -Not -Throw

                $jws = $result | ConvertFrom-Json
                { $jws.payload | ConvertFrom-Base64Url } | Should -Not -Throw
                { $jws.protected | ConvertFrom-Base64Url } | Should -Not -Throw
                { $jws.signature | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw

                $payload = $jws.payload | ConvertFrom-Base64Url
                { $payload | ConvertFrom-Json } | Should -Not -Throw

                $protected = $jws.protected | ConvertFrom-Base64Url
                { $protected | ConvertFrom-Json } | Should -Not -Throw

                $header = $protected | ConvertFrom-Json
                $header.alg | Should -BeExactly $origHeader.alg
                $header.kid | Should -BeExactly $origHeader.kid
                $header.url | Should -BeExactly $origHeader.url

                $jws.signature | Should -BeExactly '9XcxZ0lM4bMYmOo_efT8t4t1zg-tjktyUDHzVxTMmTs'
            }
        }
    }

}
