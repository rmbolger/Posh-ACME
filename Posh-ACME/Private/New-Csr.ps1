function New-Csr {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # Make sure we have an account configured
    if (!(Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
    }

    # Order verification should have already been taken care of
    $orderFolder = $Order | Get-OrderFolder
    $keyFile = Join-Path $orderFolder 'cert.key'
    $reqFile = Join-Path $orderFolder 'request.csr'

    # Check for an existing key
    if (Test-Path $keyFile -PathType Leaf) {

        $keyPair = Import-Pem -InputFile $keyFile

        if ($Order.KeyLength -notlike 'ec-*') {
            $sigAlgo = 'SHA256WITHRSA'
        } else {
            $keySize = [int]$Order.KeyLength.Substring(3)
            if ($keySize -eq 256) { $sigAlgo = 'SHA256WITHECDSA' }
            elseif ($keySize -eq 384) { $sigAlgo = 'SHA384WITHECDSA' }
            elseif ($keySize -eq 521) { $sigAlgo = 'SHA512WITHECDSA' }
        }

    # Nope, new key needed
    } else {

        Write-Verbose "Creating new private key for the certificate request."

        $sRandom = New-Object Org.BouncyCastle.Security.SecureRandom

        if ($Order.KeyLength -like 'ec-*') {

            # EC key
            Write-Debug "Creating BC EC keypair of type $($Order.KeyLength)"
            $isRSA = $false
            $keySize = [int]$Order.KeyLength.Substring(3)
            $curveOid = [Org.BouncyCastle.Asn1.Nist.NistNamedCurves]::GetOid("P-$keySize")

            if ($keySize -eq 256) { $sigAlgo = 'SHA256WITHECDSA' }
            elseif ($keySize -eq 384) { $sigAlgo = 'SHA384WITHECDSA' }
            elseif ($keySize -eq 521) { $sigAlgo = 'SHA512WITHECDSA' }

            $ecGen = New-Object Org.BouncyCastle.Crypto.Generators.ECKeyPairGenerator
            $genParam = New-Object Org.BouncyCastle.Crypto.Parameters.ECKeyGenerationParameters -ArgumentList $curveOid,$sRandom
            $ecGen.Init($genParam)
            $keyPair = $ecGen.GenerateKeyPair()

        } else {

            # RSA key
            Write-Debug "Creating BC RSA keypair of type $($Order.KeyLength)"
            $isRSA = $true
            $keySize = [int]$Order.KeyLength
            $sigAlgo = 'SHA256WITHRSA'

            $rsaGen = New-Object Org.BouncyCastle.Crypto.Generators.RsaKeyPairGenerator
            $genParam = New-Object Org.BouncyCastle.Crypto.KeyGenerationParameters -ArgumentList $sRandom,$keySize
            $rsaGen.Init($genParam)
            $keyPair = $rsaGen.GenerateKeyPair()

        }

        # export the key to a file
        Export-Pem $keyPair $keyFile

    }

    # start building the cert request

    # create the subject
    $subject = New-Object Org.BouncyCastle.Asn1.X509.X509Name("CN=$($Order.MainDomain)")

    # create a .NET Dictionary to hold our extensions because that's what BouncyCastle needs
    $extDict = New-Object 'Collections.Generic.Dictionary[Org.BouncyCastle.Asn1.DerObjectIdentifier,Org.BouncyCastle.Asn1.X509.X509Extension]'

    # create the extensions we care about
    $basicConstraints = New-Object Org.BouncyCastle.Asn1.X509.X509Extension($false, (New-Object Org.BouncyCastle.Asn1.DerOctetString(New-Object Org.BouncyCastle.Asn1.X509.BasicConstraints($false))))
    $keyUsage = New-Object Org.BouncyCastle.Asn1.X509.X509Extension($true, (New-Object Org.BouncyCastle.Asn1.DerOctetString(New-Object Org.BouncyCastle.Asn1.X509.KeyUsage([Org.BouncyCastle.Asn1.X509.KeyUsage]::DigitalSignature -bor [Org.BouncyCastle.Asn1.X509.KeyUsage]::KeyEncipherment))))
    $extKeyUsage = New-Object Org.BouncyCastle.Asn1.X509.X509Extension($false, (New-Object Org.BouncyCastle.Asn1.DerOctetString(New-Object Org.BouncyCastle.Asn1.X509.ExtendedKeyUsage([Org.BouncyCastle.Asn1.X509.KeyPurposeID]::IdKPServerAuth, [Org.BouncyCastle.Asn1.X509.KeyPurposeID]::IdKPClientAuth))))
    $ski = New-Object Org.BouncyCastle.Asn1.X509.X509Extension($false, (New-Object Org.BouncyCastle.Asn1.DerOctetString(New-Object Org.BouncyCastle.X509.Extension.SubjectKeyIdentifierStructure($keyPair.Public))))

    # create SANs based on the identifier types
    $genNames = @()
    $Order.identifiers | ForEach-Object {
        if ($_.type -eq 'dns') {
            $genNames += New-Object Org.BouncyCastle.Asn1.X509.GeneralName([Org.BouncyCastle.Asn1.X509.GeneralName]::DnsName, $_.value)
        }
        elseif ($_.type -eq 'ip') {
            $genNames += New-Object Org.BouncyCastle.Asn1.X509.GeneralName([Org.BouncyCastle.Asn1.X509.GeneralName]::IPAddress, $_.value)
        }
        else {
            Write-Warning "Skipping unexpected identifier type '$($_.type)' with value '$($_.value)'."
        }
    }
    $sans = New-Object Org.BouncyCastle.Asn1.X509.X509Extension($false, (New-Object Org.BouncyCastle.Asn1.DerOctetString(New-Object Org.BouncyCastle.Asn1.X509.GeneralNames(@(,$genNames)))))

    # add them to a DerSet object
    $extDict.Add([Org.BouncyCastle.Asn1.X509.X509Extensions]::BasicConstraints, $basicConstraints)
    $extDict.Add([Org.BouncyCastle.Asn1.X509.X509Extensions]::KeyUsage, $keyUsage)
    $extDict.Add([Org.BouncyCastle.Asn1.X509.X509Extensions]::ExtendedKeyUsage, $extKeyUsage)
    $extDict.Add([Org.BouncyCastle.Asn1.X509.X509Extensions]::SubjectAlternativeName, $sans)
    $extDict.Add([Org.BouncyCastle.Asn1.X509.X509Extensions]::SubjectKeyIdentifier, $ski)

    # add OCSP Must Staple if requested
    if ($Order.OCSPMustStaple) {
        Write-Debug "Adding OCSP Must-Staple"
        $mustStaple = New-Object Org.BouncyCastle.Asn1.X509.X509Extension($false, (New-Object Org.BouncyCastle.Asn1.DerOctetString(@(,[byte[]](0x30,0x03,0x02,0x01,0x05)))))
        $extDict.Add((New-Object Org.BouncyCastle.Asn1.DerObjectIdentifier('1.3.6.1.5.5.7.1.24')), $mustStaple)
    }

    # build the extensions DerSet
    $extensions = New-Object Org.BouncyCastle.Asn1.X509.X509Extensions($extDict)
    $extDerSet = New-Object Org.BouncyCastle.Asn1.DerSet(New-Object Org.BouncyCastle.Asn1.Pkcs.AttributePkcs([Org.BouncyCastle.Asn1.Pkcs.PkcsObjectIdentifiers]::Pkcs9AtExtensionRequest,(New-Object Org.BouncyCastle.Asn1.DerSet($extensions))))

    # create the request object
    $req = New-Object Org.BouncyCastle.Pkcs.Pkcs10CertificationRequest($sigAlgo,$subject,$keyPair.Public,$extDerSet,$keyPair.Private)

    # export the csr to a file
    Export-Pem $req $reqFile

    # return the raw Base64 encoded version
    return (ConvertTo-Base64Url $req.GetEncoded())
}
