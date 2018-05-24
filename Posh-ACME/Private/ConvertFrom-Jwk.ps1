function ConvertFrom-Jwk {
    [CmdletBinding(DefaultParameterSetName='JSON')]
    [OutputType('System.Security.Cryptography.AsymmetricAlgorithm')]
    param(
        [Parameter(ParameterSetName='JSON',Mandatory,Position=0,ValueFromPipeline)]
        [string]$JwkJson,
        [Parameter(ParameterSetName='Object',Mandatory,Position=0,ValueFromPipeline)]
        [pscustomobject]$Jwk
    )

    # RFC 7515 - JSON Web Key (JWK)
    # https://tools.ietf.org/html/rfc7517

    # Support enough of a subset of RFC 7515 to implement the ACME v2
    # protocol.
    # https://tools.ietf.org/html/draft-ietf-acme-acme-12

    # This basically includes RSA keys 2048-4096 bits and EC keys utilizing
    # P-256, P-384, or P-521 curves.

    Process {

        if ($PSCmdlet.ParameterSetName -eq 'JSON') {
            try {
                $Jwk = $JwkJson | ConvertFrom-Json
            } catch { throw }
        }

        if ('kty' -notin $Jwk.PSObject.Properties.Name) {
            throw "Invalid JWK. No 'kty' element found."
        }

        # create a KeyParameters object from the values given for each key type
        switch ($Jwk.kty) {

            'RSA' {
                $keyParams = New-Object Security.Cryptography.RSAParameters

                # make sure we have the required public key parameters per
                # https://tools.ietf.org/html/rfc7518#section-6.3.1
                $hasE = ![string]::IsNullOrWhiteSpace($Jwk.e)
                $hasN = ![string]::IsNullOrWhiteSpace($Jwk.n)
                if ($hasE -and $hasN) {
                    $keyParams.Exponent = $Jwk.e  | ConvertFrom-Base64Url -AsByteArray
                    $keyParams.Modulus  = $Jwk.n  | ConvertFrom-Base64Url -AsByteArray
                } else {
                    throw "Invalid RSA JWK. Missing one or more public key parameters."
                }

                # Add the private key parameters if they were included
                # Per https://tools.ietf.org/html/rfc7518#section-6.3.2,
                # 'd' is the only required private parameter. The rest SHOULD
                # be included and if any *are* included then they all MUST be included.
                # HOWEVER, Microsoft's RSA implementation either can't or won't create
                # a private key unless all (d,p,q,dp,dq,qi) are included.
                $hasD = ![string]::IsNullOrWhiteSpace($Jwk.D)
                $hasP = ![string]::IsNullOrWhiteSpace($Jwk.P)
                $hasQ = ![string]::IsNullOrWhiteSpace($Jwk.Q)
                $hasDP = ![string]::IsNullOrWhiteSpace($Jwk.DP)
                $hasDQ = ![string]::IsNullOrWhiteSpace($Jwk.DQ)
                $hasQI = ![string]::IsNullOrWhiteSpace($Jwk.QI)
                if ($hasD -and $hasP -and $hasQ -and $hasDP -and $hasDQ -and $hasQI) {
                    $keyParams.D        = $Jwk.d  | ConvertFrom-Base64Url -AsByteArray
                    $keyParams.P        = $Jwk.p  | ConvertFrom-Base64Url -AsByteArray
                    $keyParams.Q        = $Jwk.q  | ConvertFrom-Base64Url -AsByteArray
                    $keyParams.DP       = $Jwk.dp | ConvertFrom-Base64Url -AsByteArray
                    $keyParams.DQ       = $Jwk.dq | ConvertFrom-Base64Url -AsByteArray
                    $keyParams.InverseQ = $Jwk.qi | ConvertFrom-Base64Url -AsByteArray
                } elseif ($hasD -or $hasP -or $hasQ -or $hasDP -or $hasDQ -or $hasQI) {
                    throw "Invalid RSA JWK. Incomplete set of private key parameters."
                }

                # create the key
                $key = New-Object Security.Cryptography.RSACryptoServiceProvider
                $key.ImportParameters($keyParams)
                break;
            }

            'EC' {
                # check for a valid curve
                if ('crv' -notin $Jwk.PSObject.Properties.Name) {
                    throw "Invalid JWK. No 'crv' found for key type EC."
                }
                $Curve = switch ($jwk.crv) {
                    'P-256' { [Security.Cryptography.ECCurve+NamedCurves]::nistP256; break }
                    'P-384' { [Security.Cryptography.ECCurve+NamedCurves]::nistP384; break }
                    'P-521' { [Security.Cryptography.ECCurve+NamedCurves]::nistP521; break }
                    default { throw "Unsupported JWK curve (crv) found." }
                }

                # make sure we have the required public key parameters per
                # https://tools.ietf.org/html/rfc7518#section-6.2.1
                $hasX = ![string]::IsNullOrWhiteSpace($Jwk.x)
                $hasY = ![string]::IsNullOrWhiteSpace($Jwk.y)
                if ($hasX -and $hasY) {
                    $Q = New-Object Security.Cryptography.ECPoint
                    $Q.X = $Jwk.x | ConvertFrom-Base64Url -AsByteArray
                    $Q.Y = $Jwk.y | ConvertFrom-Base64Url -AsByteArray
                    $keyParams = New-Object Security.Cryptography.ECParameters
                    $keyParams.Q = $Q
                    $keyParams.Curve = $Curve
                } else {
                    throw "Invalid EC JWK. Missing one or more public key parameters."
                }

                # add the private key parameter
                if (![string]::IsNullOrWhiteSpace($Jwk.d)) {
                    $keyParams.D = $Jwk.d | ConvertFrom-Base64Url -AsByteArray
                }

                # create the key
                $key = [Security.Cryptography.ECDsa]::Create()
                $key.ImportParameters($keyParams)
                break;
            }
            default {
                throw "Unsupported JWK key type (kty) found."
            }
        }

        # return the key
        return $key
    }
}
