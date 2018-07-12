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
                throw "No certificate found for current order."
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


    <#
    .SYNOPSIS
        Install a Posh-ACME certificate into a Windows certificate store.

    .DESCRIPTION
        This can be used instead of the -Install parameter on New-PACertificate to import a certificate with more configurable options.

    .PARAMETER PACertificate
        The PACertificate object you want to import. This can be retrieved using Get-PACertificate and is also returned from things like New-PACertificate and Submit-Renewal.

    .PARAMETER StoreLocation
        Either 'LocalMachine' or 'CurrentUser'. Defaults to 'LocalMachine'.

    .PARAMETER StoreName
        The name of the certificate store to import to. Defaults to 'My'. The store must already exist and will not be created automatically.

    .PARAMETER NotExportable
        If specified, the private key will not be marked as Exportable.

    .EXAMPLE
        Install-PACertificate

        Install the certificate for the currently selected order to the default LocalMachine\My store.

    .EXAMPLE
        Get-PACertificate example.com | Install-PACertificate

        Install the specified certificate to the default LocalMachine\My store.

    .EXAMPLE
        Install-PACertificate -StoreLocation 'CurrentUser' -NotExportable

        Install the certificate for the currently selected order to the CurrentUser\My store and mark the private key as not exportable.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PACertificate
    #>
}
