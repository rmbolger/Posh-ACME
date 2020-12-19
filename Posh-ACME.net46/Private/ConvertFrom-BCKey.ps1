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
        $Q.X = $BCKeyPair.Public.Q.AffineXCoord.GetEncoded()
        $Q.Y = $BCKeyPair.Public.Q.AffineYCoord.GetEncoded()
        $keyParams = New-Object Security.Cryptography.ECParameters
        $keyParams.Q = $Q
        $keyParams.Curve = $Curve

        # add private param
        # For named curves (which is all we're currently using), D must have the same
        # length as X/Y params. But D doesn't have a GetEncoded() method which takes care
        # of padding the byte array like X/Y. So we have to check for proper padding and do
        # it manually.
        $dBytes = $pKey.D.ToByteArrayUnsigned()
        if ($dBytes.Length -ne $Q.X.Length) {
            $paddedD = New-Object byte[] $Q.X.Length
            $startAt = $paddedD.Length - $dBytes.Length
            [Array]::Copy($dBytes, 0, $paddedD, $startAt, $dBytes.Length)
            # set the padded D value
            $keyParams.D = $paddedD
        } else {
            # set the D value as-is because it doesn't need padding
            $keyParams.D = $dBytes
        }

        # create the key
        $key = [Security.Cryptography.ECDsa]::Create()
        $key.ImportParameters($keyParams)

        return $key

    } elseif ($BCKeyPair.Private -is [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]) {

        $pKey = $BCKeyPair.Private

        # RSAParameters requires D to be the same length as Modulus and the rest of the
        # private params to be half that length. But like the EC D value above, calling
        # ToByteArrayUnsigned() on the BouncyCastle values drops any leading zero bytes
        # which makes ImportParameters throw "Bad Data". BouncyCastle's own converter
        # takes care of the padding for us.
        $keyParams = [Org.BouncyCastle.Security.DotNetUtilities]::ToRSAParameters($pKey)

        # create the key
        $key = New-Object Security.Cryptography.RSACryptoServiceProvider
        $key.ImportParameters($keyParams)

        return $key

    } else {
        # not EC or RSA...don't know what to do with it
        throw "Unsupported key type."
    }

}
