function Complete-PAOrder {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # This is the last step for a new certificate that has reached 'valid'
    # status. We need to:
    # - download the signed cert and generate the various combinations of files
    # - calculate the renewal window
    # - add expiration/renewal time to the order
    # - Install the cert to the Windows cert store if requested
    # - output the cert object

    Begin {
        try {
            # make sure an account exists
            if (-not ($acct = Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }
            # make sure it's valid
            if ($acct.status -ne 'valid') {
                throw "Account status is $($acct.status)."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    Process {

        # make sure any order passed in is actually associated with the account
        # or if no order was specified, that there's a current order.
        if (-not $Order) {
            if (-not ($Order = Get-PAOrder)) {
                try { throw "No Order parameter specified and no current order selected. Try running Set-PAOrder first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        } elseif ($Order.MainDomain -notin (Get-PAOrder -List).MainDomain) {
            Write-Error "Order for $($Order.MainDomain) was not found in the current account's order list."
            return
        }

        # make sure the order has a valid state for this function
        if ($Order.status -ne 'valid') {
            Write-Error "Order status is '$($Order.status)' for $($Order.MainDomain). It must be 'valid' to complete. Unable to continue."
            return
        }
        if ([string]::IsNullOrWhiteSpace($Order.certificate)) {
            try { throw "Order status is valid, but no certificate URL was found." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # Download the cert chain, split it up, and generate a PFX files
        Export-PACertFiles $Order

        Write-Verbose "Updating cert expiration and renewal window"

        # Calculate the appropriate renewal window. The generally accepted suggestion
        # is 1/3 the total lifetime of the cert earlier than its expiration. For
        # example, 90 day certs renew 30 days before expiration. For longer lived
        # certs we're going to cap to renewal window at 30 days before renewal.
        $cert = Import-Pem (Join-Path ($Order | Get-OrderFolder) 'cert.cer')
        $lifetime = $cert.NotAfter - $cert.NotBefore
        $renewHours = [Math]::Max(720, ($lifetime.TotalHours / 3))

        # Set the CertExpires and RenewAfter fields
        $script:Order.CertExpires = $cert.NotAfter.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        $script:Order.RenewAfter = $cert.NotAfter.AddHours(-$renewHours).ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        Update-PAOrder -SaveOnly

        Write-Verbose "Successfully created certificate."

        $cert = Get-PACertificate

        # install to local computer store if asked
        if ($Order.Install) {
            $cert | Install-PACertificate
        }

        # output cert details
        return $cert
    }


    <#
    .SYNOPSIS
        Exports cert files for a completed order and adds suggested renewal window to the order.

    .DESCRIPTION
        Once an ACME order is finalized, the signed certificate and chain can be downloaded and combined with the local private key to generate the supported PEM and PFX files on disk. This function will also calculate the renewal window based on the signed certificate's expiration date and update the order object with that info. If the Install flag is set, this function will attempt to import the certificate into the Windows certificate store.

    .PARAMETER Order
        The ACME order to complete. The order object must be associated with the currently active ACME account.

    .EXAMPLE
        Complete-PAOrder

        Complete the current order.

    .EXAMPLE
        Get-PAOrder example.com | Complete-PAOrder

        Complete the specified order.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
