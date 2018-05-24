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
    # Windows 8/2012 and beyond for PowerShell Desktop edition. So we need a
    # shim that has an alternative for Core edition and earlier Desktop
    # edition OSes.

    if (!$PfxPass) {
        # create an empty secure string
        $PfxPass = New-Object Security.SecureString
    }

    if (Get-Command 'Import-PfxCertificate' -ErrorAction SilentlyContinue) {
        # Win 8/2012 and above (Windows PowerShell only)
        Write-Debug "Importing PFX via native Import-PfxCertificate"

        Import-PfxCertificate $PfxFile Cert:\$StoreName\$StoreLoc -Exportable -Password $PfxPass | Out-Null

    } elseif ($PSVersionTable.PSEdition -eq 'Core' -and !$IsWindows) {
        # This is a non-Windows version of PowerShell Core
        throw "Certificate import is not currently supported on non-Windows OSes"

    } else {
        # Win 7/2008R2 and below and PowerShell Core on Windows
        Write-Debug "Importing PFX via downlevel pfx import code"

        try {

            $pfxBytes = [IO.File]::ReadAllBytes($PfxFile)

            $pfx = New-Object Security.Cryptography.X509Certificates.X509Certificate2($pfxBytes,$PfxPass,'Exportable,PersistKeySet')

            $store = New-Object Security.Cryptography.X509Certificates.X509Store($StoreLoc,$StoreName)
            $store.Open("MaxAllowed")
            $store.Add($pfx)
            $store.Close()

        } finally {
            if ($store -ne $null) { $store.Dispose() }
            if ($pfx -ne $null) { $pfx.Dispose() }
        }

    }

}
