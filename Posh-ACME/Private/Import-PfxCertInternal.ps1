function Import-PfxCertInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$PfxFile,
        [securestring]$PfxPass,
        [string]$StoreName = 'LocalMachine',
        [string]$StoreLoc = 'My'
    )

    # The PowerShell native Import-PfxCertificate function only exists on
    # Windows 8/2012 and beyond for PowerShell Desktop edition. It also seems
    # to have some weird limitations in how it stores the private key rendering
    # the resulting cert unusable in some circumstances.
    # https://github.com/MicrosoftDocs/windows-powershell-docs/issues/295

    # So we're going to use the raw .NET cert libraries to do what we need to do.
    # and should work "everywhere" we care about.

    if (!$PfxPass) {
        # create an empty secure string
        $PfxPass = New-Object Security.SecureString
    }

    if ($PSVersionTable.PSEdition -eq 'Core' -and !$IsWindows) {
        # This is a non-Windows version of PowerShell Core
        throw "Certificate import is not currently supported on non-Windows OSes"

    } else {
        Write-Debug "Importing PFX"

        try {

            $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)

            $pfxBytes = [IO.File]::ReadAllBytes($PfxFile)

            $pfx = New-Object Security.Cryptography.X509Certificates.X509Certificate2($pfxBytes,$PfxPass,'Exportable,PersistKeySet,MachineKeySet')

            $store = New-Object Security.Cryptography.X509Certificates.X509Store($StoreLoc,$StoreName)
            $store.Open("MaxAllowed")
            $store.Add($pfx)
            $store.Close()

        } finally {
            if ($null -ne $store) { $store.Dispose() }
            if ($null -ne $pfx) { $pfx.Dispose() }
        }

    }

}
