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
        } elseif ($Order.Name -notin (Get-PAOrder -List).Name) {
            Write-Error "Order '$($Order.Name)' was not found in the current account's order list."
            return
        }

        # make sure the order has a valid state for this function
        if ($Order.status -ne 'valid') {
            Write-Error "Order '$($Order.Name)' status is '$($Order.status)'. It must be 'valid' to complete. Unable to continue."
            return
        }
        if ([string]::IsNullOrWhiteSpace($Order.certificate)) {
            try { throw "Order '$($Order.Name)' status is valid, but no certificate URL was found." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # Download the cert chain, split it up, and generate a PFX files
        Export-PACertFiles $Order

        Write-Verbose "Updating cert expiration and renewal window"

        # Calculate the appropriate renewal window. The generally accepted suggestion
        # is 1/3 the total lifetime of the cert earlier than its expiration. For
        # example, 90 day certs renew 30 days before expiration. For longer lived
        # certs we're going to cap to renewal window at 30 days before renewal.
        $cert = Import-Pem (Join-Path $Order.Folder 'cert.cer')
        $lifetime = $cert.NotAfter - $cert.NotBefore
        $renewHours = [Math]::Max(720, ($lifetime.TotalHours / 3))

        # Set the CertExpires and RenewAfter fields
        $Order | Add-Member 'CertExpires' $cert.NotAfter.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) -Force
        $Order | Add-Member 'RenewAfter' $cert.NotAfter.AddHours(-$renewHours).ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) -Force
        Update-PAOrder $Order -SaveOnly

        Write-Verbose "Successfully created certificate."

        $cert = Get-PACertificate

        # install to local computer store if asked
        if ($Order.Install) {
            $cert | Install-PACertificate
        }

        # output cert details
        return $cert
    }
}
