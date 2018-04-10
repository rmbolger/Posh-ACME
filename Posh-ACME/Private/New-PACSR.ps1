function New-PACSR {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,

        [Parameter(ParameterSetName='NewKey',Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='4096'

        # [Parameter(ParameterSetName='OldKey',Position=1)]
        # [ValidateScript({Test-ValidKey $_ -ThrowOnFail})]
        # [Security.Cryptography.AsymmetricAlgorithm]$Key
    )

    # There are a number of ways to go here, none are great, and all of them are very Windows-only
    # for the time being. We're gonna try to make the legacy COM based CertEnroll APIs work for now
    # because it ultimately gives us a more control. But if that falls through, we could also just
    # call out to to certreq.exe with a dynamically created inf file. There's a new
    # CertificateRequest class in .NET Core 2.0, but since the rest of the module is currently
    # targetting Windows .NET Framework, that's a no go. Though supposedly it's being added in
    # .NET 4.7.2 which is currently in preview. But even after release, we may not want to force
    # people on to the bleeding edge framework just to get an LE cert.

    # IObjectId::InitializeFromAlgorithmName
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa376796%28v=vs.85%29.aspx
    $XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID = 3
    $XCN_CRYPT_OID_INFO_PUBKEY_ANY = 0
    $AlgorithmFlagsNone = 0

    # X509KeySpec enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa379409%28v=vs.85%29.aspx
    $XCN_AT_KEYEXCHANGE = 1

    # X509PrivateKeyUsageFlags enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa379417(v=vs.85).aspx
    $XCN_NCRYPT_ALLOW_DECRYPT_FLAG = 0x1
    $XCN_NCRYPT_ALLOW_SIGNING_FLAG = 0x2
    $XCN_NCRYPT_ALLOW_KEY_AGREEMENT_FLAG = 0x4

    # X509PrivateKeyExportFlags enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa379412(v=vs.85).aspx
    $XCN_NCRYPT_ALLOW_EXPORT_FLAG = 0x1
    $XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG = 0x2
    $XCN_NCRYPT_ALLOW_ARCHIVING_FLAG = 0x4
    $XCN_NCRYPT_ALLOW_PLAINTEXT_ARCHIVING_FLAG = 0x8

    # X509CertificateEnrollmentContext enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa379399(v=vs.85).aspx
    $ContextUser = 0x1

    # X500NameFlags enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa379394%28v=vs.85%29.aspx
    $XCN_CERT_NAME_STR_NONE = 0

    # AlternativeNameType enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa374830%28v=vs.85%29.aspx
    $XCN_CERT_ALT_NAME_DNS_NAME = 3

    # EncodingType enumeration
    # https://msdn.microsoft.com/en-us/library/windows/desktop/aa374936(v=vs.85).aspx
    $XCN_CRYPT_STRING_BASE64 = 0x1
    $XCN_CRYPT_STRING_NOCRLF = 0x40000000


    # create the private key if necessary
    if ('NewKey' -eq $PSCmdlet.ParameterSetName) {

        # Until we figure out how to convert the .NET AsymmetricAlgorithm keys to IX509PrivateKey
        # objects, we're going to have to create these directly using the COM interfaces

        $isRSA = $true
        $HashAlgo = 'SHA256'
        if ($KeyLength -like 'ec-*') {
            $isRSA = $false
            $keySize = [int]$KeyLength.Substring(3)
        } else {
            $keySize = [int]$KeyLength
        }

        $algo = New-Object -ComObject X509Enrollment.CObjectId
        if ($isRSA) {
            $algo.InitializeFromAlgorithmName($XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID,$XCN_CRYPT_OID_INFO_PUBKEY_ANY,$AlgorithmFlagsNone,'RSA')
        } elseif ($keySize -eq 256) {
            $algo.InitializeFromAlgorithmName($XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID,$XCN_CRYPT_OID_INFO_PUBKEY_ANY,$AlgorithmFlagsNone,'ECDSA_P256')
        } elseif ($keySize -eq 384) {
            $algo.InitializeFromAlgorithmName($XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID,$XCN_CRYPT_OID_INFO_PUBKEY_ANY,$AlgorithmFlagsNone,'ECDSA_P384')
            $HashAlgo = 'SHA384'
        } elseif ($keySize -eq 521) {
            $algo.InitializeFromAlgorithmName($XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID,$XCN_CRYPT_OID_INFO_PUBKEY_ANY,$AlgorithmFlagsNone,'ECDSA_P521')
            $HashAlgo = 'SHA512'
        }

        # create the private key
        $privKey = New-Object -ComObject X509Enrollment.CX509PrivateKey -Property @{
            ProviderName = 'Microsoft Software Key Storage Provider';
            Algorithm = $algo;
            Length = $keySize;
            KeySpec = $XCN_AT_KEYEXCHANGE;
            KeyUsage = ($XCN_NCRYPT_ALLOW_DECRYPT_FLAG -bor $XCN_NCRYPT_ALLOW_SIGNING_FLAG -bor $XCN_NCRYPT_ALLOW_KEY_AGREEMENT_FLAG);
            ExportPolicy = ($XCN_NCRYPT_ALLOW_EXPORT_FLAG -bor $XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG -bor $XCN_NCRYPT_ALLOW_ARCHIVING_FLAG -bor $XCN_NCRYPT_ALLOW_PLAINTEXT_ARCHIVING_FLAG);
            MachineContext = $false;
        }
        $privKey.Create()
    }

    # start building the request
    $req = New-Object -ComObject X509Enrollment.CX509CertificateRequestPkcs10
    $req.InitializeFromPrivateKey($ContextUser, $privKey, [string]::Empty)
    $req.SuppressDefaults = $true

    # set the hashing algorithm
    $HashAlgoId = New-Object -ComObject X509Enrollment.CObjectId
    $HashAlgoId.InitializeFromValue(([Security.Cryptography.Oid]$HashAlgo).Value)
    $req.HashAlgorithm = $HashAlgoId

    # set the subject
    $dn = New-Object -ComObject X509Enrollment.CX500DistinguishedName
    $dn.Encode("CN=$($Domain[0])", $XCN_CERT_NAME_STR_NONE)
    $req.Subject = $dn

    # add the typical KeyUsage flags
    $keyUsage = New-Object -ComObject X509Enrollment.CX509ExtensionKeyUsage
    $keyUsage.InitializeEncode([int][Security.Cryptography.X509Certificates.X509KeyUsageFlags](('DigitalSignature','KeyEncipherment')))
    $keyUsage.Critical = $true
    $req.X509Extensions.Add($keyUsage)

    # add Server/Client Authentication extensions
    $ekuOids = New-Object -ComObject X509Enrollment.CObjectIds
    '1.3.6.1.5.5.7.3.1', '1.3.6.1.5.5.7.3.2' | ForEach-Object {
        $oid = New-Object -ComObject X509Enrollment.CObjectId
        $oid.InitializeFromValue($_)
        $ekuOids.Add($oid)
    }
    $eku = New-Object -ComObject X509Enrollment.CX509ExtensionEnhancedKeyUsage
    $eku.InitializeEncode($ekuOids)
    $req.X509Extensions.Add($eku)

    # add SANs
    $sans = New-Object -ComObject X509Enrollment.CAlternativeNames
    $Domain | ForEach-Object {
        $san = New-Object -ComObject X509Enrollment.CAlternativeName
        $san.InitializeFromString($XCN_CERT_ALT_NAME_DNS_NAME, $_)
        $sans.Add($san)
    }
    $extSans = New-Object -ComObject X509Enrollment.CX509ExtensionAlternativeNames
    $extSans.InitializeEncode($sans)
    $req.X509Extensions.Add($extSans)

    # if ($OcspMustStaple) {
    #     # X509Extension(OID(1.3.6.1.5.5.7.1.24), SEQUENCE(INTEGER(5)))
    #     $objectId = New-Object -ComObject X509Enrollment.CObjectId
    #     $objectId.InitializeFromValue("1.3.6.1.5.5.7.1.24")
    #     $ocsp = New-Object -ComObject X509Enrollment.CX509Extension
    #     $ocsp.Initialize($objectId, 1, [System.Convert]::ToBase64String((Encode-ASN1Sequence(Encode-ASN1Integer 5))))
    #     $request.X509Extensions.Add($ocsp)
    # }

    # encode the request
    $req.Encode()

    # create the enrollment object
    $enroll = New-Object -ComObject X509Enrollment.CX509Enrollment
    $enroll.InitializeFromRequest($req)
    $enroll.CertificateFriendlyName = $Domain[0]

    $csr = $enroll.CreateRequest($XCN_CRYPT_STRING_BASE64 -bor $XCN_CRYPT_STRING_NOCRLF) | ConvertTo-Base64Url -FromBase64

    return $csr
}
