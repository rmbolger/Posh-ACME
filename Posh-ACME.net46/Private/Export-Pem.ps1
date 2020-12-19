function Export-Pem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [psobject]$InputObject,
        [Parameter(Mandatory,Position=1)]
        [string]$OutputFile
    )

    if ($InputObject -is [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]) {
        $BCKeyPair = $InputObject

        if ($BCKeyPair.Private -is [Org.BouncyCastle.Crypto.Parameters.ECPrivateKeyParameters]) {

            # grab the things we need to build an ECPrivateKeyStructure that includes the public key
            $privParam = $BCKeyPair.Private
            $orderBitLength = $privParam.Parameters.N.BitLength
            $x962 = [Org.BouncyCastle.Asn1.X9.X962Parameters]::new($privParam.PublicKeyParamSet)
            $pubKey = [Org.BouncyCastle.Asn1.DerBitString]::new($BCKeyPair.Public.Q.GetEncoded())

            # create the structure
            $privKeyStruct = [Org.BouncyCastle.Asn1.Sec.ECPrivateKeyStructure]::new(
                $orderBitLength, $privParam.D, $pubKey, $x962
            )

            # ECPrivateKeyStructure.GetDerEncoded() seems to return a SEC1 version of the key
            $privKeyStr = [Convert]::ToBase64String($privKeyStruct.GetDerEncoded())

            # SEC1 means 'EC PRIVATE KEY' rather than just 'PRIVATE KEY' for PKCS8
            # build an array with the proper header/footer
            $pem = @('-----BEGIN EC PRIVATE KEY-----')
            for ($i=0; $i -lt $privKeyStr.Length; $i += 64) {
                $pem += $privKeyStr.Substring($i,[Math]::Min(64,($privKeyStr.Length-$i)))
            }
            $pem += '-----END EC PRIVATE KEY-----'

        } elseif ($BCKeyPair.Private -is [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]) {

            # build the PrivateKeyInfo object
            $rsaInfo = [Org.BouncyCastle.Pkcs.PrivateKeyInfoFactory]::CreatePrivateKeyInfo($BCKeyPair.Private)

            # the PrivateKeyInfo.GetDerEncoded() method seems to return a PKCS8 version of the key
            $privKeyStr = [Convert]::ToBase64String($rsaInfo.GetDerEncoded())

            # PKCS8 means 'PRIVATE KEY' rather than 'RSA PRIVATE KEY'
            # build an array with the proper header/footer
            $pem = @('-----BEGIN PRIVATE KEY-----')
            for ($i=0; $i -lt $privKeyStr.Length; $i += 64) {
                $pem += $privKeyStr.Substring($i,[Math]::Min(64,($privKeyStr.Length-$i)))
            }
            $pem += '-----END PRIVATE KEY-----'

        } else {
            throw "Unsupported BouncyCastle KeyPair type"
        }

    } elseif ($InputObject -is [Org.BouncyCastle.Pkcs.Pkcs10CertificationRequest]) {

        # get the raw Base64 encoded version
        $reqStr = [Convert]::ToBase64String($InputObject.GetEncoded())

        # build an array with the header/footer
        # https://stackoverflow.com/questions/28628744/is-there-a-spec-for-csr-begin-headers
        # Apparently including "NEW" is the old way
        $pem = @('-----BEGIN CERTIFICATE REQUEST-----')
        for ($i=0; $i -lt $reqStr.Length; $i += 64) {
            $pem += $reqStr.Substring($i,[Math]::Min(64,($reqStr.Length-$i)))
        }
        $pem += '-----END CERTIFICATE REQUEST-----'

    } elseif ($InputObject -is [array]) {
        # this should be a string array output from Split-PemChain that we just
        # need to write to disk with proper line endings.
        $pem = $InputObject

    } else {
        throw "Unsuppored InputObject type"
    }

    # resolve relative paths
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

    # Usually, PEM files are ANSI/ASCII encoded with UNIX line endings which means none of the
    # normal PowerShell stuff for outputting files will work. So we'll use a .NET StreamWriter
    # instead.
    try {
        $sw = [IO.StreamWriter]::new($OutputFile, $false, [Text.Encoding]::ASCII)
        $sw.NewLine = "`n"
        foreach ($line in $pem) {
            $sw.WriteLine($line)
        }
    } finally { if ($null -ne $sw) { $sw.Close() } }

}
