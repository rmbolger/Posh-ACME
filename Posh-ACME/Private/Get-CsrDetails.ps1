function Get-CsrDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('CSRString')]
        [string]$CSRPath
    )

    # Given a PEM formatted CSR file path or raw string value, we need to parse the
    # request and return a hashtable with the following parsed details to the caller:
    #
    #   Domain    : The collection of FQDNs found in the CN and/or SAN attributes
    #   KeyLength : The key length value using our Posh-ACME nomeclature
    #   OCSPMustStaple : Boolean indicating whether the OCSP Must Staple flag is set
    #   Base64Url : The Base64Url encoded bytes of the raw request
    #   PemLines  : The original lines from the file/string PEM request content

    # We're going to try to allow for CSRs being passed directly as a string value
    # in addition to a filesystem path. Since the BC PemReader currently requires
    # explicit BEGIN/END header and footer, we're going to assume that anything
    # missing them is a file path.
    if ($CSRPath -cnotlike '*CERTIFICATE REQUEST*') {

        Write-Debug "CSRPath didn't match CERTIFICATE REQUEST"

        # normalize the CSR path and make sure it exists
        $CSRPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CSRPath)
        if (-not (Test-Path $CSRPath -PathType Leaf)) {
            throw "CSR file not found at $CSRPath"
        }

        $importParams = @{
            InputFile = $CSRPath
        }

        $details = @{
            PemLines = Get-Content $CSRPath
        }

    } else {

        $importParams = @{
            InputString = $CSRPath
        }

        $details = @{
            PemLines = $CSRPath.Trim() -split "(?:`r)?`n"
        }
    }

    # parse the CSR into a [Org.BouncyCastle.Asn1.Pkcs.CertificationRequest]
    Write-Debug "Attempting to import CSR pem"
    $csr = Import-Pem @importParams
    if ($csr -isnot [Org.BouncyCastle.Pkcs.Pkcs10CertificationRequest]) {
        throw "Specified CSR was unable to be parsed as a certificate request."
    }
    $details.Base64Url = ConvertTo-Base64Url $csr.GetEncoded()

    # determine the KeyLength
    $pubKey = $csr.GetPublicKey()
    if ($pubKey -is [Org.BouncyCastle.Crypto.Parameters.RsaKeyParameters]) {
        # RSA key, so KeyLength is just the bit length of the Modulus
        $details.KeyLength = $pubKey.Modulus.BitLength.ToString()
        if (-not (Test-ValidKeyLength $details.KeyLength)) {
            throw "RSA key length from CSR is out of the supported range. ($($details.KeyLength))"
        }
    } elseif ($pubKey -is [Org.BouncyCastle.Crypto.Parameters.ECPublicKeyParameters]) {
        # EC key, make sure the curve is supported
        $curve = $pubKey.Parameters.Curve
        if ($curve -eq [Org.BouncyCastle.Asn1.Nist.NistNamedCurves]::GetByName('P-256').Curve) {
            $details.KeyLength = 'ec-256'
        } elseif ($curve -eq [Org.BouncyCastle.Asn1.Nist.NistNamedCurves]::GetByName('P-384').Curve) {
            $details.KeyLength = 'ec-384'
        } elseif ($curve -eq [Org.BouncyCastle.Asn1.Nist.NistNamedCurves]::GetByName('P-521').Curve) {
            $details.KeyLength = 'ec-521'
        } else {
            throw "Unsupported ECC curve. $($pubKey.Parameters.Curve.ToString())"
        }
    } else {
        throw "Unsupported key type."
    }
    Write-Debug "KeyLength = $($details.KeyLength)"

    # [Org.BouncyCastle.Asn1.Pkcs.CertificationRequestInfo]
    $csrInfo = $csr.GetCertificationRequestInfo()

    # grab the CN value
    $cn = ($csrInfo.Subject.GetValueList([Org.BouncyCastle.Asn1.X509.X509Name]::CN))[0]
    Write-Debug "CN = $cn"
    if ($cn) { $details.Domain = @($cn) }
    else { $details.Domain = @() }

    # grab the rest of the attributes [Org.BouncyCastle.Asn1.Asn1Set]
    # The Asn1Set is basically a nested collection of DerSequence objects
    $attr = $csrInfo.Attributes

    # Check if we have any attributes at all
    if ($attr.count -eq 0) {
        # throw if we have no CN
        if ($details.Domain.Count -eq 0) { throw "No Common Name (CN) or Subject Alternative Name (SAN) extensions found in certificate request." }

        Write-Warning "No Certficate Attributes found in CR."
        $details.OCSPMustStaple = $false
        return $details
    }

    # Find the sequence for "Certificate Extensions" (oid 1.2.840.113549.1.9.14)
    # [0] is the OID, [1] is the nested Asn1Set,
    # [1][0] should be the only DerSequence within the Ans1Set that contains additional nested DerSequence objects
    $extensions = ($attr | Where-Object { $_.Id -eq '1.2.840.113549.1.9.14'})[1][0]
    if (-not $extensions) {
        # throw if we have no names
        if ($details.Domain.Count -eq 0) { throw "No Common Name (CN) or Subject Alternative Name (SAN) extensions found in certificate request." }

        Write-Warning "No Certificate Extensions sequence found in CSR."
        $details.OCSPMustStaple = $false
        return $details
    }

    # Now find the sequence for "Subject Alternative Name" (oid 2.5.29.17)
    # [0] is the OID, [1] is the DerOctetString
    if ($sanSeq = $extensions | Where-Object { $_.Id -eq '2.5.29.17' }) {
        # convert to [Org.BouncyCastle.Asn1.X509.GeneralNames]
        $genNames = [Org.BouncyCastle.Asn1.X509.GeneralNames]::GetInstance([Org.BouncyCastle.Asn1.Asn1Object]::FromByteArray($sanSeq[1].GetOctets()))
        # and grab just the DNS names
        $SANs = ($genNames.GetNames() | Where-Object { $_.TagNo -eq 2 }).Name
    }
    if ($SANs) {
        Write-Debug "SANs = $(($SANs -join ','))"
        $details.Domain += $SANs | Where-Object { $_ -notin $details.Domain }
    }

    # throw if we have no names
    if ($details.Domain.Count -eq 0) { throw "No Common Name (CN) or Subject Alternative Name (SAN) extensions found in certificate request." }

    # Find the sequence for OCSP Must-Staple (oid 1.3.6.1.5.5.7.1.24)
    # and determine whether it's set
    if ($ocspSeq = $extensions | Where-Object { $_.Id -eq '1.3.6.1.5.5.7.1.24'}) {
        $details.OCSPMustStaple = ($ocspSeq[1].ToString() -eq '#3003020105')
    } else {
        $details.OCSPMustStaple = $false
    }
    Write-Debug "OCSP Must-Staple = $($details.OCSPMustStaple)"

    return $details
}
