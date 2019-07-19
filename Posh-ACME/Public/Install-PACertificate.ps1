function Install-PACertificate {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [PSTypeName('PoshACME.PACertificate')]$PACertificate
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

        Write-Verbose "Importing $($PACertificate.Subject) certificate to Windows certificate store."
        Import-PfxCertInternal $PACertificate.PfxFullChain -PfxPass $PACertificate.PfxPass
    }


    <#
    .SYNOPSIS
        Install a Posh-ACME certificate into the local computer's certificate store.

    .DESCRIPTION
        This can be used instead of the -Install parameter on New-PACertificate to import a certificate into the local computer's certificate store.

    .EXAMPLE
        Install-PACertificate

        Install the certificate associated with the currently selected order.

    .EXAMPLE
        Get-PACertificate example.com | Install-PACertificate

        Install the specified certificate.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PACertificate
    #>
}
