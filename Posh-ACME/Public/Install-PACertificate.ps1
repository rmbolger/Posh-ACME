function Install-PACertificate {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [PSTypeName('PoshACME.PACertificate')]$PACertificate,
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine',
        [string]$StoreName = 'My',
        [switch]$NotExportable
    )

    Process {

        if (-not $IsWindows -and 'Desktop' -ne $PSEdition) {
            Write-Warning "Install-PACertificate currently only works on Windows OSes"
            return
        }

        if (-not $PACertificate) {
            # try to get the certificate associated with the current order
            $PACertificate = Get-PACertificate

            if (-not $PACertificate) {
                try { throw "No certificate found for current order." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }

        Write-Verbose "Importing $($PACertificate.Subject) certificate to $StoreLocation\$StoreName."
        $importArgs = @{
            PfxFile = $PACertificate.PfxFullChain
            PfxPass = $PACertificate.PfxPass
            StoreLocation = $StoreLocation
            StoreName = $StoreName
            NotExportable = $NotExportable.IsPresent
        }
        Import-PfxCertInternal @importArgs
    }
}
