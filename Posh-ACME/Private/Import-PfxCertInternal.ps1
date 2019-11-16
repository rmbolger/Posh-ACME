function Import-PfxCertInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$PfxFile,
        [securestring]$PfxPass,
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine',
        [string]$StoreName = 'My',
        [switch]$NotExportable
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

            # read the file into memory
            $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
            $pfxBytes = [IO.File]::ReadAllBytes($PfxFile)

            # build the key flags
            $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
            if (-not $NotExportable) {
                $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
            }
            if ('LocalMachine' -eq $StoreLocation) {
                $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet
            } else {
                $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet
            }
            Write-Debug "Key Flags: $keyFlags"

            # create the certificate object
            $pfx = [Security.Cryptography.X509Certificates.X509Certificate2]::new($pfxBytes,$PfxPass,$keyFlags)

            # add it to the store
            $store = [Security.Cryptography.X509Certificates.X509Store]::new($StoreName,$StoreLocation)
            $store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
            $store.Add($pfx)
            $store.Close()

        } finally {
            if ($null -ne $store) { $store.Dispose() }
            if ($null -ne $pfx) { $pfx.Dispose() }
        }

    }

}
