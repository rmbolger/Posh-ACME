function Export-CertPfx {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$CertFile,
        [Parameter(Mandatory,Position=1)]
        [string]$KeyFile,
        [Parameter(Mandatory,Position=2)]
        [string]$OutputFile,
        [string]$ChainFile,
        [string]$FriendlyName,
        [string]$PfxPass=''
    )

    $CertFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CertFile)
    $KeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyFile)
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    $ChainFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ChainFile)

    # read in the files as native BouncyCastle objects
    $key  = Import-Pem -InputFile $KeyFile     # [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]
    $cert = Import-Pem -InputFile $CertFile    # [Org.BouncyCastle.X509.X509Certificate]

    # BouncyCastle won't let use use a null value for a cert/key alias in the PFX file and Windows
    # in some cases doesn't like the empty string default we were using previously. So we'll
    # use the subject CN value unless something non-empty was passed in.
    if ([String]::IsNullOrWhiteSpace($FriendlyName)) {
        $FriendlyName = $cert.Subject.GetValueList([Org.BouncyCastle.Asn1.X509.X509Name]::CN)[0]
    }

    # create a new Pkcs12StoreBuilder
    $storebuilder = New-Object Org.BouncyCastle.Pkcs.Pkcs12StoreBuilder
    # Certs could be left unencrypted since it's just the public part, but BouncyCastle does not support it - it also does not expose PKCS5 Scheme 2 for certs.
    $storebuilder.SetCertAlgorithm([Org.BouncyCastle.Asn1.Pkcs.PkcsObjectIdentifiers]::PbeWithShaAnd3KeyTripleDesCbc.Id) | Out-Null
    # Configure the Pkcs12Store to use PKCS5 Scheme 2 for private keys, using AES256CBC and HMAC-SHA256. 
    $storebuilder.SetKeyAlgorithm([Org.BouncyCastle.Asn1.Nist.NistObjectIdentifiers]::IdAes256Cbc.Id, [Org.BouncyCastle.Asn1.Pkcs.PkcsObjectIdentifiers]::IdHmacWithSha256.Id) | Out-Null
    $store = $storebuilder.Build()

    # add the private key
    try {
        $store.SetKeyEntry($FriendlyName, $key.Private, @($cert))
    } catch { throw }

    # add the chain certs if specified
    if ('ChainFile' -in $PSBoundParameters.Keys) {
        $pems = @(Split-PemChain $ChainFile)

        foreach ($pem in $pems) {
            $ca = Import-Pem -InputString ($pem -join [Environment]::NewLine)

            # try to parse the subject to use as the alias
            if ($ca.SubjectDN -match "CN=([^,]+)") {
                $caName = $matches[1]
            } else {
                $caName = $ca.SerialNumber
            }

            try {
                $store.SetCertificateEntry($caName, $ca)
            } catch { throw }
        }
    }

    # save it
    $sRandom = New-Object Org.BouncyCastle.Security.SecureRandom
    try {
        $fs = New-Object IO.FileStream($OutputFile,'Create')
        $store.Save($fs, $PfxPass, $sRandom)
    } finally {
        if ($null -ne $fs) { $fs.Close() }
    }

}
