function ConvertFrom-BCKey {
    [CmdletBinding()]
    [OutputType('System.Security.Cryptography.AsymmetricAlgorithm')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]$BCKeyPair
    )

    if ($BCKeyPair.Private -is [Org.BouncyCastle.Crypto.Parameters.ECPrivateKeyParameters]) {

        $pKey = $BCKeyPair.Private

        # convert the curve
        $Curve = switch ($pKey.Parameters.Curve.GetType().Name) {
            'SecP256R1Curve' { [Security.Cryptography.ECCurve+NamedCurves]::nistP256; break }
            'SecP384R1Curve' { [Security.Cryptography.ECCurve+NamedCurves]::nistP384; break }
            'SecP521R1Curve' { [Security.Cryptography.ECCurve+NamedCurves]::nistP521; break }
            default { throw "Unsupported curve found." }
        }

        # add public params
        $Q = New-Object Security.Cryptography.ECPoint
        $Q.X = $BCKeyPair.Public.Q.X.ToBigInteger().ToByteArrayUnsigned()
        $Q.Y = $BCKeyPair.Public.Q.Y.ToBigInteger().ToByteArrayUnsigned()
        $keyParams = New-Object Security.Cryptography.ECParameters
        $keyParams.Q = $Q
        $keyParams.Curve = $Curve

        # add private param
        $keyParams.D = $pKey.D.ToByteArrayUnsigned()

        # create the key
        $key = [Security.Cryptography.ECDsa]::Create()
        $key.ImportParameters($keyParams)

        return $key

    } elseif ($BCKeyPair.Private -is [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]) {

        $pKey = $BCKeyPair.Private

        $keyParams = New-Object Security.Cryptography.RSAParameters
        $keyParams.Exponent = $pKey.PublicExponent.ToByteArrayUnsigned()
        $keyParams.Modulus  = $pKey.Modulus.ToByteArrayUnsigned()
        $keyParams.D        = $pKey.Exponent.ToByteArrayUnsigned()
        $keyParams.P        = $pKey.P.ToByteArrayUnsigned()
        $keyParams.Q        = $pKey.Q.ToByteArrayUnsigned()
        $keyParams.DP       = $pKey.DP.ToByteArrayUnsigned()
        $keyParams.DQ       = $pKey.DQ.ToByteArrayUnsigned()
        $keyParams.InverseQ = $pKey.QInv.ToByteArrayUnsigned()

        # create the key
        $key = New-Object Security.Cryptography.RSACryptoServiceProvider
        $key.ImportParameters($keyParams)

        return $key

    } else {
        # not EC or RSA...don't know what to do with it
        throw "Unsupported key type."
    }

}
