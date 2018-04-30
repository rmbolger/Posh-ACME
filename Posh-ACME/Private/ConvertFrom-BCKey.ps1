function ConvertFrom-BCKey {
    [CmdletBinding()]
    [OutputType('System.Security.Cryptography.AsymmetricAlgorithm')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]$BCKeyPair
    )

    if ($BCKeyPair.Private -is [Org.BouncyCastle.Crypto.Parameters.ECPrivateKeyParameters]) {

        # TODO: Implement this
        throw "Unsupported key type."

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
