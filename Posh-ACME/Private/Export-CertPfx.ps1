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
        [string]$FriendlyName='',
        [string]$PfxPass=''
    )

    $CertFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CertFile)
    $KeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyFile)
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    $ChainFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ChainFile)

    # read in the files as native BouncyCastle objects
    $key  = Import-Pem $KeyFile     # [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]
    $cert = Import-Pem $CertFile    # [Org.BouncyCastle.X509.X509Certificate]

    # create a new Pkcs12Store
    $store = New-Object Org.BouncyCastle.Pkcs.Pkcs12Store

    # add the private key
    $store.SetKeyEntry($FriendlyName, $key.Private, @($cert))

    # add the chain certs if specified
    if ('ChainFile' -in $PSBoundParameters.Keys) {
        $pems = @(Split-PemChain $ChainFile)

        foreach ($pem in $pems) {
            $ca = Import-Pem -InputString ($pem -join '')

            # try to parse the subject to use as the alias
            if ($ca.SubjectDN -match "CN=([^,]+)") {
                $caName = $matches[1]
            } else {
                $caName = $ca.SerialNumber
            }

            $store.SetCertificateEntry($caName, $ca)
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
