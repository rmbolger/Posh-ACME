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

    # create a new Pkcs12Store
    $store = New-Object Org.BouncyCastle.Pkcs.Pkcs12Store

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
