function ConvertTo-Jwk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
        [switch]$PublicOnly,
        [switch]$AsJson,
        [switch]$AsPrettyJson
    )

    # RFC 7517 - JSON Web Key (JWK)
    # https://tools.ietf.org/html/rfc7517

    # Support enough of a subset of RFC 7517 to implement the ACME v2
    # protocol.
    # https://tools.ietf.org/html/draft-ietf-acme-acme-12

    # This basically includes RSA keys 2048-4096 bits and EC keys utilizing
    # P-256, P-384, or P-521 curves.

    # Things to remember:
    # 'kty' is case-sensitive per
    # https://tools.ietf.org/html/rfc7517#section-4.1
    # Some things using JWKs require keys to be in alphabetical order. So we might
    # as well just always output them as such.

    Process {

        if ($Key -is [Security.Cryptography.RSA]) {

            if ($PublicOnly -Or $Key.PublicOnly) {
                # grab the public parameters only
                $keyParams = $Key.ExportParameters($false)
                $jwkObj = $keyParams | Select-Object `
                    @{L='e';  E={ConvertTo-Base64Url $_.Exponent}},
                    @{L='kty';E={'RSA'}},
                    @{L='n';  E={ConvertTo-Base64Url $_.Modulus}}
            } else {
                # grab all parameters
                $keyParams = $Key.ExportParameters($true)
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

        } elseif ($Key -is [Security.Cryptography.ECDsa]) {

            # For all curves currently supported by RFC 7518, the 'crv' value is 'P-<key size'
            # https://tools.ietf.org/html/rfc7518#section-6.2.1.1
            $crv = "P-$($Key.KeySize)"

            # since there's no PublicOnly property, we have to fake it by trying to export
            # the private parameters and catching the error
            try {
                $Key.ExportParameters($true) | Out-Null
                $noPrivate = $false
            } catch { $noPrivate = $true }

            if ($PublicOnly -or $noPrivate) {
                $keyParams = $Key.ExportParameters($false)
                $jwkObj = $keyParams | Select-Object `
                    @{L='crv';E={$crv}},
                    @{L='kty';E={'EC'}},
                    @{L='x';  E={ConvertTo-Base64Url $_.Q.X}},
                    @{L='y';  E={ConvertTo-Base64Url $_.Q.Y}}
            } else {
                $keyParams = $Key.ExportParameters($true)
                $jwkObj = $keyParams | Select-Object `
                    @{L='crv';E={$crv}},
                    @{L='d';  E={ConvertTo-Base64Url $_.D}},
                    @{L='kty';E={'EC'}},
                    @{L='x';  E={ConvertTo-Base64Url $_.Q.X}},
                    @{L='y';  E={ConvertTo-Base64Url $_.Q.Y}}
            }

        } else {
            throw 'Unsupported key type'
        }

        if ($AsPrettyJson) {
            return ($jwkObj | ConvertTo-Json)
        } elseif ($AsJson) {
            return ($jwkObj | ConvertTo-Json -Compress)
        } else {
            return $jwkObj
        }

    }

}
