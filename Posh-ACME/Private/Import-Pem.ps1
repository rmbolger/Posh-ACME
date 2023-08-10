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
        # This should be a single string value with at least the header/footer
        # on their own line
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

}
