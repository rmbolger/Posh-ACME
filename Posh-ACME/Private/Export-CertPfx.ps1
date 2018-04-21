function Export-CertPfx {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$CertFile,
        [Parameter(Mandatory,Position=1)]
        [string]$KeyFile,
        [Parameter(Mandatory,Position=2)]
        [string]$OutputFile,
        [Parameter(Mandatory,Position=3)]
        [string]$ExportPass,
        [string]$Alias
    )

    $CertFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CertFile)
    $KeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyFile)
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

    # read in the files as native BouncyCastle objects
    $key  = Import-Pem $KeyFile     # [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]
    $cert = Import-Pem $CertFile    # [Org.BouncyCastle.X509.X509Certificate]

    # create a new Pkcs12Store
    $store = New-Object Org.BouncyCastle.Pkcs.Pkcs12Store

    # add the private key
    if (!$Alias) {
        $Alias = "{$((New-Guid).ToString().ToUpper())}"
    }
    $store.SetKeyEntry($Alias, $key.Private, @($cert))

    # save it
    $sRandom = New-Object Org.BouncyCastle.Security.SecureRandom
    try {
        $fs = New-Object IO.FileStream($OutputFile,'Create')
        $store.Save($fs, $ExportPass, $sRandom)
    } finally {
        if ($fs -ne $null) { $fs.Close() }
    }

}
