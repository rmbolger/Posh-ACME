function Import-Pem {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='File',Mandatory,Position=0)]
        [string]$InputFile,
        [Parameter(ParameterSetName='String',Mandatory)]
        [string]$InputString
    )

    # DER uses TLV (Tag/Length/Value) triplets.
    # First byte is the tag - https://en.wikipedia.org/wiki/X.690#Types
    # Second byte is either the total length of the value when less than 0x80 (128)
    #     or the number of bytes that make up the value not counting the most significant bit (the 8)
    #     So 0x77 (less than 0x80) means length is 119 (0x77) bytes
    #        0x82 (more than 0x80) means the length is the next 2 (0x82-0x80) bytes
    # Value starts the byte after the length bytes end

    if ('File' -eq $PSCmdlet.ParameterSetName) {
        # normalize the file path and read it in
        $InputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InputFile)
        $pemStr = (Get-Content $InputFile) -join ''
    } else {
        $pemStr = $InputString.Replace("`n",'')
    }

    # private keys
    if ($pemStr -like '*-----BEGIN *PRIVATE KEY-----*' -and $pemStr -like '*-----END *PRIVATE KEY-----*') {

        $base64 = $pemStr.Substring($pemStr.IndexOf('KEY-----')+8)
        $base64 = $base64.Substring(0,$base64.IndexOf('-'))
        $keyBytes = [Convert]::FromBase64String($base64)

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

        # throw if we don't find a SEQUENCE tag in the first byte
        if ($keyBytes[0] -ne 0x30) { throw "Invalid private key: No sequence in first byte" }

        # read in the bytes as an Asn1Sequence object
        $seq = [Org.BouncyCastle.Asn1.Asn1Sequence]::GetInstance($keyBytes)

        # check for RSA keys
        if ($seq[0] -eq 0 -and
            ($seq[1] -is [Org.BouncyCastle.Asn1.DerInteger] -or
            ($seq[1].Count -eq 2 -and $seq[1][0] -eq [Org.BouncyCastle.Asn1.Pkcs.PkcsObjectIdentifiers]::RsaEncryption)) ) {

            Write-Debug "Found RSA key type"

            # We can deal with either PKCS1 or PKCS8, because the PKCS1 can be extracted from PKCS8
            if ($seq.Count -eq 3) {
                Write-Debug "Extracting RSA PKCS1 from PKCS8"
                $seq = [Org.BouncyCastle.Asn1.Asn1Sequence]::GetInstance($seq[2].GetOctets())
            }

            # The resulting sequence should have 9 items, otherwise it's incomplete/malformed
            if ($seq.Count -ne 9) { throw "Invalid sequence in RSA private key" }

            # build the key parameters we'll need to build the AsymmetricCipherKey later
            $rsa = [Org.BouncyCastle.Asn1.Pkcs.RsaPrivateKeyStructure]::GetInstance($seq)
            $pubSpec = New-Object Org.BouncyCastle.Crypto.Parameters.RsaKeyParameters($false,$rsa.Modulus,$rsa.PublicExponent)
            $privSpec = New-Object Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters(
                $rsa.Modulus, $rsa.PublicExponent, $rsa.PrivateExponent,
                $rsa.Prime1, $rsa.Prime2, $rsa.Exponent1, $rsa.Exponent2,
                $rsa.Coefficient)

        # check fo EC keys
        } elseif ($seq[0] -eq 1 -or
                  ($seq[0] -eq 0 -and $seq[1].Count -eq 2 -and
                   $seq[1][0] -eq [Org.BouncyCastle.Asn1.X9.X9ObjectIdentifiers]::IdECPublicKey) ) {

            Write-Debug "Found EC key type"

            # Haven't figured out how to extract the key from PKCS8 yet because it's not the same format
            # as a raw SEC1 key
            if ($seq.Count -eq 3) {
                throw "Unsupported PKCS8 EC key"
            }

            # Makes sure we're dealing with a raw SEC1 key rather than a PKCS8 container
            if ($seq.Count -ne 4) { "Unsupported EC key encoding" }

            # build the key parameters we'll need to build the AsymmetricCipherKey later
            $pKey = [Org.BouncyCastle.Asn1.Sec.ECPrivateKeyStructure]::GetInstance($seq)
            $ecPubKeyOid = [Org.BouncyCastle.Asn1.DerObjectIdentifier]([Org.BouncyCastle.Asn1.X9.X9ObjectIdentifiers]::IdECPublicKey)
            $algId = New-Object Org.BouncyCastle.Asn1.X509.AlgorithmIdentifier($ecPubKeyOid,$pKey.GetParameters())
            $privInfo = New-Object Org.BouncyCastle.Asn1.Pkcs.PrivateKeyInfo($algId,$pKey.ToAsn1Object())
            $privSpec = [Org.BouncyCastle.Security.PrivateKeyFactory]::CreateKey($privInfo)
            $pubKey = $pKey.GetPublicKey()

            if ($pubKey -ne $null) {
                $pubInfo = New-Object Org.BouncyCastle.Asn1.X509.SubjectPublicKeyInfo($algId,$pubKey.GetBytes())
                $pubSpec = [Org.BouncyCastle.Security.PublicKeyFactory]::CreateKey($pubInfo)
            } else {
                $pubSpec = [Org.BouncyCastle.Crypto.Generators.ECKeyPairGenerator]::GetCorrespondingPublicKey([Org.BouncyCastle.Crypto.Parameters.ECPrivateKeyParameters]$privSpec)
            }

        } else {
            throw "Unsupported private key type"
        }

        # build the key and return it
        $newKey = New-Object Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair($pubSpec,$privSpec)
        return $newKey

    # certificates
    } elseif ($pemStr -like '*-----BEGIN CERTIFICATE-----*' -and $pemStr -like '*-----END CERTIFICATE-----*') {

        # For certs, we can use the native PemReader to make things easier
        if ('File' -eq $PSCmdlet.ParameterSetName) {
            try {
                $sr = New-Object IO.StreamReader($InputFile)
                $reader = New-Object Org.BouncyCastle.OpenSsl.PemReader($sr)
                $cert = $reader.ReadObject()
            } finally {
                if ($null -ne $sr) { $sr.Close() }
            }
        } else {
            # get the byte array from the pem string
            $base64 = $pemStr.Substring($pemStr.IndexOf('CERTIFICATE-----')+16)
            $base64 = $base64.Substring(0,$base64.IndexOf('-'))
            $certBytes = [Convert]::FromBase64String($base64)

            # let BC parse it
            $certParser = New-Object Org.BouncyCastle.X509.X509CertificateParser
            $cert = $certParser.ReadCertificate($certBytes)
        }
        return $cert

    } else {
        throw "Unsupported PEM type"
    }

}
