function ConvertTo-Jwk {
    [CmdletBinding(DefaultParameterSetName='RSAKey')]
    param(
        [Parameter(ParameterSetName='RSAKey',Mandatory,Position=0,ValueFromPipeline)]
        [Security.Cryptography.RSA]$RSAKey,
        [Parameter(ParameterSetName='ECKey',Mandatory,Position=0,ValueFromPipeline)]
        [Security.Cryptography.ECDsa]$ECKey,
        [switch]$PublicOnly,
        [switch]$Pretty
    )

    # RFC 7517 - JSON Web Key (JWK)
    # https://tools.ietf.org/html/rfc7517

    # Support enough of a subset of RFC 7517 to implement the ACME v2
    # protocol.
    # https://tools.ietf.org/html/draft-ietf-acme-acme-09

    # This basically includes RSA keys 2048-4096 bits and EC keys utilizing
    # P-256, P-384, or P-521 curves.

    # Things to remember:
    # 'kty' is case-sensitive per
    # https://tools.ietf.org/html/rfc7517#section-4.1
    # Some things using JWKs require keys to be in alphabetical order. So we might
    # as well just always output them as such.

    Process {

        switch ($PSCmdlet.ParameterSetName) {

            'RSAKey' {
                if ($PublicOnly -Or $RSAKey.PublicOnly) {
                    # grab the public parameters only
                    $keyParams = $RSAKey.ExportParameters($false)
                    $jwkObj = $keyParams | Select-Object `
                        @{L='e';  E={ConvertTo-Base64Url $_.Exponent}},
                        @{L='kty';E={'RSA'}},
                        @{L='n';  E={ConvertTo-Base64Url $_.Modulus}}
                } else {
                    # grab all parameters
                    $keyParams = $RSAKey.ExportParameters($true)
                    $jwkObj = $keyParams | Select-Object `
                        @{L='d';  E={ConvertTo-Base64Url $_.D}},
                        @{L='dp'; E={ConvertTo-Base64Url $_.DP}},
                        @{L='dq'; E={ConvertTo-Base64Url $_.DQ}},
                        @{L='e';  E={ConvertTo-Base64Url $_.Exponent}},
                        @{L='kty';E={'RSA'}},
                        @{L='n';  E={ConvertTo-Base64Url $_.Modulus}},
                        @{L='p';  E={ConvertTo-Base64Url $_.P}},
                        @{L='q';  E={ConvertTo-Base64Url $_.Q}},
                        @{L='qi'; E={ConvertTo-Base64Url $_.InverseQ}}
                }
            }

            'ECKey' {
                # For all curves currently supported by RFC 7518, the 'crv' value is 'P-<key size'
                # https://tools.ietf.org/html/rfc7518#section-6.2.1.1
                $crv = "P-$($ECKey.KeySize)"

                # since there's no PublicOnly property, we have to fake it by trying to export
                # the private parameters and catching the error
                try {
                    $ECKey.ExportParameters($true) | Out-Null
                    $noPrivate = $false
                } catch { $noPrivate = $true }

                if ($PublicOnly -or $noPrivate) {
                    $keyParams = $ECKey.ExportParameters($false)
                    $jwkObj = $keyParams | Select-Object `
                        @{L='crv';E={$crv}},
                        @{L='kty';E={'EC'}},
                        @{L='x';  E={ConvertTo-Base64Url $_.Q.X}},
                        @{L='y';  E={ConvertTo-Base64Url $_.Q.Y}}
                } else {
                    $keyParams = $ECKey.ExportParameters($true)
                    $jwkObj = $keyParams | Select-Object `
                        @{L='crv';E={$crv}},
                        @{L='d';  E={ConvertTo-Base64Url $_.D}},
                        @{L='kty';E={'EC'}},
                        @{L='x';  E={ConvertTo-Base64Url $_.Q.X}},
                        @{L='y';  E={ConvertTo-Base64Url $_.Q.Y}}
                }
            }

            default { throw 'Unsupported key type' }
        }

        if ($Pretty) {
            return ($jwkObj | ConvertTo-Json)
        } else {
            return ($jwkObj | ConvertTo-Json -Compress)
        }
        
    }

}