function Import-PfxCertInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$PfxFile,
        [string]$StoreName = 'LocalMachine',
        [string]$StoreLoc = 'My'
    )

    # The PowerShell native Import-PfxCertificate function only exists on
    # Windows 8/2012 and beyond. So we need a shim that has an alternative
    # for earlier OSes.

    $secureEmpty = New-Object Security.SecureString

    if (Get-Command 'Import-PfxCertificate' -ErrorAction SilentlyContinue) {
        # Win 8/2012 and above
        Write-Debug "Using native Import-PfxCertificate"

        Import-PfxCertificate $test.PfxFile Cert:\LocalMachine\My -Exportable -Password $secureEmpty | Out-Null

    } else {
        # Win 7/2008R2 and below
        Write-Debug "Using downlevel pfx import code"

        try {

            $pfx = New-Object Security.Cryptography.X509Certificates.X509Certificate2
            $pfx.import($PfxFile,$secureEmpty,'Exportable,PersistKeySet')

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
