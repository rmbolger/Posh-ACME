function Import-Pem {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='File',Mandatory,Position=0)]
        [string]$InputFile,
        [Parameter(ParameterSetName='String',Mandatory)]
        [string]$InputString
    )

    # BouncyCastle has a lovely PemReader class that can spit out certs, keys, csrs, etc.
    # We have to do a little extra work for PKCS8 encoded private keys though.

    if ('File' -eq $PSCmdlet.ParameterSetName) {
        # normalize the file path and read it in
        $InputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InputFile)
        $pemStr = Get-Content $InputFile -Raw
    } else {
        # This should be a single string value with all of the line breaks intact
        $pemStr = $InputString
    }

    # parse the PEM
    try {
        $sr = [IO.StringReader]::new($pemStr)
        $reader = [Org.BouncyCastle.OpenSsl.PemReader]::new($sr)
        $pemObj = $reader.ReadObject()
    } finally {
        if ($null -ne $sr) { $sr.Close() }
    }

    if ($pemObj -is [Org.BouncyCastle.X509.X509Certificate] -or
        $pemObj -is [Org.BouncyCastle.Pkcs.Pkcs10CertificationRequest] -or
        $pemObj -is [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair])
    {
        # Certs, Requests, and private keys that get parsed as a full key pair
        # are all things we can just return as-is
        Write-Debug "PemReader found '$($pemObj.GetType())'. Returning as-is"
        return $pemObj
    }
    elseif ($pemObj -is [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]) {
        # A PKCS8 encoded RSA private key comes out as just the private key
        # parameters. We have to generate the public key parameters and fold
        # them into a full key pair object.
        Write-Debug "PemReader found '$($pemObj.GetType())'. Attempting to convert to AsymmetricCipherKeyPair."

        $pubSpec = [Org.BouncyCastle.Crypto.Parameters.RsaKeyParameters]::new(
            $false,$pemObj.Modulus,$pemObj.PublicExponent
        )

        # $pemObj is our private parameters
        return [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]::new($pubSpec,$pemObj)
    }
    elseif ($pemObj -is [Org.BouncyCastle.Crypto.Parameters.ECPrivateKeyParameters]) {
        # A PKCS8 encoded EC private key comes out as just the key parameters
        # We have to transform them into a full key pair object
        Write-Debug "PemReader found '$($pemObj.GetType())'. Attempting to convert to AsymmetricCipherKeyPair."

        $multiplier = [Org.BouncyCastle.Math.EC.Multiplier.FixedPointCombMultiplier]::new()
        $q = $multiplier.Multiply($pemObj.Parameters.G, $pemObj.D)
        $pubSpec = [Org.BouncyCastle.Crypto.Parameters.ECPublicKeyParameters]::new(
            $pemObj.AlgorithmName, $q, $pemObj.PublicKeyParamSet
        )

        # $pemObj is our private parameters
        return [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]::new($pubSpec,$pemObj)
    }
    else {
        # not sure what we ended up with
        throw "PemReader found unsupported '$($pemObj.GetType())'."
    }

    return $pemObj

    # Old info we don't need anymore

    # DER uses TLV (Tag/Length/Value) triplets.
    # First byte is the tag - https://en.wikipedia.org/wiki/X.690#Types
    # Second byte is either the total length of the value when less than 0x80 (128)
    #     or the number of bytes that make up the value not counting the most significant bit (the 8)
    #     So 0x77 (less than 0x80) means length is 119 (0x77) bytes
    #        0x82 (more than 0x80) means the length is the next 2 (0x82-0x80) bytes
    # Value starts the byte after the length bytes end

    # We need to identify enough of the DER encoded ASN.1 structure to differentiate between
    # RSA vs EC keys in order to call the right BouncyCastle libraries to import them.

    # On the keys we care about, the first tag is always a SEQUENCE (0x30) and the first
    # tag within that sequence is an INTEGER (0x02) which is a Version field.
    # Version = 1 always means an EC key
    # Version = 0 either means a PKCS1 RSA key or a PKCS8 key that could be either RSA or EC
    #           Need to check the second item in the sequence to say for sure.
    # If Second tag is INTEGER, PKCS1 RSA key
    # If Second tag is a SEQUENCE, PKCS8 and need to check first child for Algorithm OID
    # Child = 1.2.840.113549.1.1.1 (RSA) [Org.BouncyCastle.Asn1.Pkcs.PkcsObjectIdentifiers]::RsaEncryption
    # Child = 1.2.840.10045.2.1    (EC)  [Org.BouncyCastle.Asn1.X9.X9ObjectIdentifiers]::IdECPublicKey

}
