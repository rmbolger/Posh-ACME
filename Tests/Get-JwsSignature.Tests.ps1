Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "Get-JwsSignature" {

    Context "Using bad keys" {
        InModuleScope Posh-ACME {
        }
    }

    Context "Using sample RSA Key From RFC" {
        InModuleScope Posh-ACME {

            # create the sample RS256 key from the RFC
            # https://tools.ietf.org/html/rfc7515#appendix-A.2.1
            $sampleJwk = '{"kty":"RSA",' +
                '"n":"ofgWCuLjybRlzo0tZWJjNiuSfb4p4fAkd_wWJcyQoTbji9k0l8W26mPddxHmfHQp-Vaw-4qPCJrcS2mJPMEzP1Pt0Bm4d4QlL-yRT-SFd2lZS-pCgNMsD1W_YpRPEwOWvG6b32690r2jZ47soMZo9wGzjb_7OMg0LOL-bSf63kpaSHSXndS5z5rexMdbBYUsLA9e-KXBdQOS-UTo7WTBEMa2R2CapHg665xsmtdVMTBQY4uDZlxvb3qCo5ZwKh9kG4LT6_I5IhlJH7aGhyxXFvUK-DWNmoudF8NAco9_h9iaGNj8q2ethFkMLs91kzk2PAcDTW9gb54h4FRWyuXpoQ",' +
                '"e":"AQAB",' +
                '"d":"Eq5xpGnNCivDflJsRQBXHx1hdR1k6Ulwe2JZD50LpXyWPEAeP88vLNO97IjlA7_GQ5sLKMgvfTeXZx9SE-7YwVol2NXOoAJe46sui395IW_GO-pWJ1O0BkTGoVEn2bKVRUCgu-GjBVaYLU6f3l9kJfFNS3E0QbVdxzubSu3Mkqzjkn439X0M_V51gfpRLI9JYanrC4D4qAdGcopV_0ZHHzQlBjudU2QvXt4ehNYTCBr6XCLQUShb1juUO1ZdiYoFaFQT5Tw8bGUl_x_jTj3ccPDVZFD9pIuhLhBOneufuBiB4cS98l2SR_RQyGWSeWjnczT0QU91p1DhOVRuOopznQ",' +
                '"p":"4BzEEOtIpmVdVEZNCqS7baC4crd0pqnRH_5IB3jw3bcxGn6QLvnEtfdUdiYrqBdss1l58BQ3KhooKeQTa9AB0Hw_Py5PJdTJNPY8cQn7ouZ2KKDcmnPGBY5t7yLc1QlQ5xHdwW1VhvKn-nXqhJTBgIPgtldC-KDV5z-y2XDwGUc",' +
                '"q":"uQPEfgmVtjL0Uyyx88GZFF1fOunH3-7cepKmtH4pxhtCoHqpWmT8YAmZxaewHgHAjLYsp1ZSe7zFYHj7C6ul7TjeLQeZD_YwD66t62wDmpe_HlB-TnBA-njbglfIsRLtXlnDzQkv5dTltRJ11BKBBypeeF6689rjcJIDEz9RWdc",' +
                '"dp":"BwKfV3Akq5_MFZDFZCnW-wzl-CCo83WoZvnLQwCTeDv8uzluRSnm71I3QCLdhrqE2e9YkxvuxdBfpT_PI7Yz-FOKnu1R6HsJeDCjn12Sk3vmAktV2zb34MCdy7cpdTh_YVr7tss2u6vneTwrA86rZtu5Mbr1C1XsmvkxHQAdYo0",' +
                '"dq":"h_96-mK1R_7glhsum81dZxjTnYynPbZpHziZjeeHcXYsXaaMwkOlODsWa7I9xXDoRwbKgB719rrmI2oKr6N3Do9U0ajaHF-NKJnwgjMd2w9cjz3_-kyNlxAr2v4IKhGNpmM5iIgOS1VZnOZ68m6_pbLBSp3nssTdlqvd0tIiTHU",' +
                '"qi":"IYd7DHOhrWvxkwPQsRM2tOgrjbcrfvtQJipd-DlcxyVuuM9sQLdgjVk2oy26F0EmpScGLq2MowX7fhd_QJQ3ydy5cY7YIBi87w93IKLEdfnbJtoOPLUW0ITrJReOgo1cq9SbsxYawBgfp_gh6A5603k2-ZQwVK0JKSHuLFkuQ3U"' +
                '}' | ConvertFrom-Json

            # https://msdn.microsoft.com/en-us/library/system.security.cryptography.rsaparameters(v=vs.110).aspx
            $keyParams = New-Object Security.Cryptography.RSAParameters
            $keyParams.Exponent = $sampleJwk.e  | ConvertFrom-Base64Url -AsByteArray
            $keyParams.Modulus  = $sampleJwk.n  | ConvertFrom-Base64Url -AsByteArray
            $keyParams.P        = $sampleJwk.p  | ConvertFrom-Base64Url -AsByteArray
            $keyParams.Q        = $sampleJwk.q  | ConvertFrom-Base64Url -AsByteArray
            $keyParams.DP       = $sampleJwk.dp | ConvertFrom-Base64Url -AsByteArray
            $keyParams.DQ       = $sampleJwk.dq | ConvertFrom-Base64Url -AsByteArray
            $keyParams.InverseQ = $sampleJwk.qi | ConvertFrom-Base64Url -AsByteArray
            $keyParams.D        = $sampleJwk.d  | ConvertFrom-Base64Url -AsByteArray

            # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.rsacryptoserviceprovider.importparameters?view=netframework-4.6.1
            $sampleKey = New-Object Security.Cryptography.RSACryptoServiceProvider
            $sampleKey.ImportParameters($keyParams)


            It "rfc7515#appendix-A.6 RS256" {
                $protectedHeader = 'eyJhbGciOiJSUzI1NiJ9' # {"alg":"RS256"}
                $payload = 'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
                $sampleInput = "$protectedHeader.$payload"
                $expectedSig = 'cC4hiUPoj9Eetdgtv3hF80EGrhuB__dzERat0XF9g2VtQgr9PJbu3XOiZj5RZmh7AAuHIm4Bh-0Qc_lF5YKt_O8W2Fp5jujGbds9uJdbF9CUAr7t1dnZcAcQjbKBYNX4BAynRFdiuB--f_nZLgrnbyTyWzO75vRK5h6xBArLIARNPvkSjtQBMHlb1L07Qe7K0GarZRmB_eSN9383LcOLn6_dO--xi12jzDwusC-eOkHWEsqtFZESc6BfI7noOPqvhJ1phCnvWh6IeYI2w9QOYEUipUTI8np6LbgGY9Fs98rqVt5AXLIhWkWywlVmtVrBp0igcN_IoypGlUPQGe77Rw'

                Get-JwsSignature -Message $sampleInput -JwsAlgorithm 'RS256' -Key $sampleKey | Should -BeExactly $expectedSig
            }

        }
    }

    Context "Using sample ECDSA Key From RFC" {
        InModuleScope Posh-ACME {

            # create the sample EC256 key from the RFC
            # https://tools.ietf.org/html/rfc7515#appendix-A.3.1
            $sampleJwk = '{"kty":"EC",' +
                '"crv":"P-256",' +
                '"x":"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU",' +
                '"y":"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0",' +
                '"d":"jpsQnnGQmL-YBIffH1136cspYG6-0iY7X1fCE9-E9LI"' +
                '}' | ConvertFrom-Json

            # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.ecparameters
            # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.ecpoint
            # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.eccurve
            $Q = New-Object Security.Cryptography.ECPoint
            $Q.X = $sampleJwk.x | ConvertFrom-Base64Url -AsByteArray
            $Q.Y = $sampleJwk.y | ConvertFrom-Base64Url -AsByteArray
            $keyParams = New-Object Security.Cryptography.ECParameters
            $keyParams.D = $sampleJwk.d | ConvertFrom-Base64Url -AsByteArray
            $keyParams.Q = $Q
            $keyParams.Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7') # nistP256

            $sampleKey = [Security.Cryptography.ECDsa]::Create()
            $sampleKey.ImportParameters($keyParams)

            It "rfc7515#appendix-A.6 ES256" {
                $protectedHeader = 'eyJhbGciOiJFUzI1NiJ9' # {"alg":"ES256"}
                $payload = 'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
                $sampleInput = "$protectedHeader.$payload"

                $result = Get-JwsSignature -Message $sampleInput -JwsAlgorithm 'ES256' -Key $sampleKey

                # Apparently ECDSA is non-deterministic which means signing the same data
                # with the same key won't always produce the same result.
                # https://stackoverflow.com/questions/27462280/ecdsacng-signature-generation-using-signdata-or-signhash-give-different-result
                #
                # So the only way I can think of to test for now is the VerifyData method using
                # the public portion of the sample key
                # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.ecdsa.verifydata
                $keyParamsPub = $sampleKey.ExportParameters($false) # $false = don't include private data
                $sampleKeyPub = [Security.Cryptography.ECDsa]::Create()
                $sampleKeyPub.ImportParameters($keyParamsPub)

                $sampleInputBytes = [Text.Encoding]::ASCII.GetBytes($sampleInput)
                $resultBytes = ConvertFrom-Base64Url $result -AsByteArray

                $sampleKeyPub.VerifyData($sampleInputBytes,$resultBytes) | Should -Be $true
            }
        }
    }

}
