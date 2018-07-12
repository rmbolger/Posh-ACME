function ConvertFrom-Jwk {
    [CmdletBinding(DefaultParameterSetName='JSON')]
    [OutputType('System.Security.Cryptography.AsymmetricAlgorithm')]
    [OutputType('Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair')]
    param(
        [Parameter(ParameterSetName='JSON',Mandatory,Position=0,ValueFromPipeline)]
        [string]$JwkJson,
        [Parameter(ParameterSetName='Object',Mandatory,Position=0,ValueFromPipeline)]
        [pscustomobject]$Jwk,
        [switch]$AsBC
    )

    # RFC 7515 - JSON Web Key (JWK)
    # https://tools.ietf.org/html/rfc7517

    # Support enough of a subset of RFC 7515 to implement the ACME v2
    # protocol (RFC 8555).
    # https://tools.ietf.org/html/rfc8555

    # This basically includes RSA keys 2048-4096 bits and EC keys utilizing
    # P-256, P-384, or P-521 curves.

    Process {

        if ($PSCmdlet.ParameterSetName -eq 'JSON') {
            try {
                $Jwk = $JwkJson | ConvertFrom-Json -EA Stop
            } catch { throw }
        }

        if ([String]::IsNullOrWhiteSpace($Jwk.kty)) {
            throw "Invalid JWK. Missing 'kty' parameter."
        }
        if ($Jwk.kty -notin 'RSA','EC') {
            throw "Invalid JWK. Unsupported 'kty' element found."
        }

        # validate RSA parameters
        if ('RSA' -eq $Jwk.kty) {
            # error if any public params are missing
            'n','e' | ForEach-Object {
                if ([String]::IsNullOrWhiteSpace($Jwk.$_)) {
                    throw "Invalid RSA JWK. Missing '$_' parameter."
                }
            }
            $publicOnly = $true

            # for private params, we either want all or none
            $privCount = @('d','p','q','dp','dq','qi' | Where-Object {
                -not [String]::IsNullOrWhiteSpace($Jwk.$_)
            }).Count
            if ($privCount -gt 0 -and $privCount -lt 6) {
                throw "Invalid RSA JWK. Missing one or more private parameters."
            }
            elseif ($privCount -eq 6) {
                $publicOnly = $false
            }
        }

        # validate EC parameters
        if ('EC' -eq $Jwk.kty) {
            # error if any public params are missing
            'crv','x','y' | ForEach-Object {
                if ([String]::IsNullOrWhiteSpace($Jwk.$_)) {
                    throw "Invalid EC JWK. Missing '$_' parameter."
                }
            }
            $publicOnly = $true
            if (-not [String]::IsNullOrWhiteSpace($Jwk.d)) {
                $publicOnly = $false
            }
        }

        if ('RSA' -eq $Jwk.kty -and -not $AsBC) {
            # create a .NET AsymmetricAlgorithm (RSACryptoServiceProvider)

            $keyParams = [Security.Cryptography.RSAParameters]::new()

            # make sure we have the required public key parameters per
            # https://tools.ietf.org/html/rfc7518#section-6.3.1
            $keyParams.Exponent = $Jwk.e | ConvertFrom-Base64Url -AsByteArray
            $keyParams.Modulus  = $Jwk.n | ConvertFrom-Base64Url -AsByteArray

            # Add the private key parameters if they were included
            # Per https://tools.ietf.org/html/rfc7518#section-6.3.2,
            # 'd' is the only required private parameter. The rest SHOULD
            # be included and if any *are* included then they all MUST be included.
            # HOWEVER, Microsoft's RSA implementation either can't or won't create
            # a private key unless all (d,p,q,dp,dq,qi) are included.
            if (-not $publicOnly) {
                $keyParams.D        = $Jwk.d  | ConvertFrom-Base64Url -AsByteArray
                $keyParams.P        = $Jwk.p  | ConvertFrom-Base64Url -AsByteArray
                $keyParams.Q        = $Jwk.q  | ConvertFrom-Base64Url -AsByteArray
                $keyParams.DP       = $Jwk.dp | ConvertFrom-Base64Url -AsByteArray
                $keyParams.DQ       = $Jwk.dq | ConvertFrom-Base64Url -AsByteArray
                $keyParams.InverseQ = $Jwk.qi | ConvertFrom-Base64Url -AsByteArray
            }

            # create and return the key
            $key = [Security.Cryptography.RSACryptoServiceProvider]::new()
            $key.ImportParameters($keyParams)
            return $key

        }
        elseif ('EC' -eq $Jwk.kty -and -not $AsBC) {
            # create a .NET AsymmetricAlgorithm (ECDsa)

            # check for a valid curve
            $Curve = switch ($jwk.crv) {
                'P-256' { [Security.Cryptography.ECCurve+NamedCurves]::nistP256; break }
                'P-384' { [Security.Cryptography.ECCurve+NamedCurves]::nistP384; break }
                'P-521' { [Security.Cryptography.ECCurve+NamedCurves]::nistP521; break }
                default { throw "Unsupported JWK curve (crv) found: $($Jwk.crv)." }
            }

            # make sure we have the required public key parameters per
            # https://tools.ietf.org/html/rfc7518#section-6.2.1
            $Q = [Security.Cryptography.ECPoint]::new()
            $Q.X = $Jwk.x | ConvertFrom-Base64Url -AsByteArray
            $Q.Y = $Jwk.y | ConvertFrom-Base64Url -AsByteArray
            $keyParams = [Security.Cryptography.ECParameters]::new()
            $keyParams.Q = $Q
            $keyParams.Curve = $Curve

            if (-not $publicOnly) {
                # add the private key parameter
                $keyParams.D = $Jwk.d | ConvertFrom-Base64Url -AsByteArray
            }

            # create and return the key
            $key = [Security.Cryptography.ECDsa]::Create()
            $key.ImportParameters($keyParams)
            return $key

        }
        elseif ('RSA' -eq $Jwk.kty -and $AsBC) {
            # create a BouncyCastle AsymmetricCipherKeyPair (RSA)

            # create public N (Modulus) and E (Exponent)
            $nBytes = $Jwk.n | ConvertFrom-Base64Url -AsByteArray
            $eBytes = $Jwk.e | ConvertFrom-Base64Url -AsByteArray
            $n = [Org.BouncyCastle.Math.BigInteger]::new(1, $nBytes)
            $e = [Org.BouncyCastle.Math.BigInteger]::new(1, $eBytes)

            # build the public parameters
            $pubKeyParam = [Org.BouncyCastle.Crypto.Parameters.RsaKeyParameters]::new(
                $false, $n, $e
            )

            if ($publicOnly) {
                # BouncyCastle won't let us return a full key pair without the private
                # portion, so just return the public parameters for now
                return $pubKeyParam
            }
            else {
                # create private pieces (D, P, Q, DP, DQ, QI)
                $dBytes = $Jwk.d | ConvertFrom-Base64Url -AsByteArray
                $pBytes = $Jwk.p | ConvertFrom-Base64Url -AsByteArray
                $qBytes = $Jwk.q | ConvertFrom-Base64Url -AsByteArray
                $dpBytes = $Jwk.dp | ConvertFrom-Base64Url -AsByteArray
                $dqBytes = $Jwk.dq | ConvertFrom-Base64Url -AsByteArray
                $qiBytes = $Jwk.qi | ConvertFrom-Base64Url -AsByteArray
                $d = [Org.BouncyCastle.Math.BigInteger]::new(1, $dBytes)
                $p = [Org.BouncyCastle.Math.BigInteger]::new(1, $pBytes)
                $q = [Org.BouncyCastle.Math.BigInteger]::new(1, $qBytes)
                $dp = [Org.BouncyCastle.Math.BigInteger]::new(1, $dpBytes)
                $dq = [Org.BouncyCastle.Math.BigInteger]::new(1, $dqBytes)
                $qi = [Org.BouncyCastle.Math.BigInteger]::new(1, $qiBytes)

                # build the private parameters
                $privKeyParam = [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]::new(
                    $n, $e, $d, $p, $q, $dp, $dq, $qi
                )

                # return the full keypair
                return [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]::new(
                    $pubKeyParam, $privKeyParam
                )
            }

        }
        elseif ('EC' -eq $Jwk.kty -and $AsBC) {
            # create a BouncyCastle AsymmetricCipherKeyPair (EC)

            # find the curve and its oid (aka PublicKeyParamSet)
            $crv = [Org.BouncyCastle.Asn1.Nist.NistNamedCurves]::GetByName($Jwk.crv)
            $crvOid = [Org.BouncyCastle.Asn1.Nist.NistNamedCurves]::GetOid($Jwk.crv)

            # create the ECPoint, Q
            $xBytes = $Jwk.x | ConvertFrom-Base64Url -AsByteArray
            $yBytes = $Jwk.y | ConvertFrom-Base64Url -AsByteArray
            $x = [Org.BouncyCastle.Math.BigInteger]::new(1, $xBytes)
            $y = [Org.BouncyCastle.Math.BigInteger]::new(1, $yBytes)
            $q = $crv.Curve.CreatePoint($x, $y)

            # build the public parameters
            $pubKeyParam = [Org.BouncyCastle.Crypto.Parameters.ECPublicKeyParameters]::new(
                'EC', $q, $crvOid
            )

            if ($publicOnly) {
                # BouncyCastle won't let us return a full key pair without the private
                # portion, so just return the public parameters for now
                return $pubKeyParam
            }
            else {
                # create the BigInteger, D
                $dBytes = $Jwk.d | ConvertFrom-Base64Url -AsByteArray
                $d = [Org.BouncyCastle.Math.BigInteger]::new(1, $dBytes)

                # build the private parameters
                $privKeyParam = [Org.BouncyCastle.Crypto.Parameters.ECPrivateKeyParameters]::new(
                    'EC', $d, $crvOid
                )

                # return the full keypair
                return [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]::new(
                    $pubKeyParam, $privKeyParam
                )
            }

        }

    }
}
