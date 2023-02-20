function Submit-OrderFinalize {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # The purpose of this function is to complete the order process by sending our
    # certificate request and wait for it to generate the signed cert. We'll poll
    # the order until it's valid, invalid, or our timeout elapses.

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
        if ($Order.status -ne 'ready') {
            Write-Error "Order '$($Order.Name)' status is '$($Order.status)'. It must be 'ready' to finalize. Unable to continue."
            return
        }

        # Use the provided CSR if it exists
        # or generate one if necessary.
        if ([String]::IsNullOrWhiteSpace($order.CSRBase64Url)) {
            Write-Verbose "Creating new certificate request with key length $($Order.KeyLength)$(if ($Order.OCSPMustStaple){' and OCSP Must-Staple'})."
            $csr = New-Csr @Order
        } else {
            Write-Verbose "Using the provided certificate request."
            $csr = $order.CSRBase64Url
        }

        # build the protected header
        $header = @{
            alg   = $acct.alg;
            kid   = $acct.location;
            nonce = $script:Dir.nonce;
            url   = $Order.finalize;
        }

        # send the request
        try {
            $body = "{`"csr`":`"$csr`"}"
            Invoke-ACME $header $body $acct -EA Stop | Out-Null
        } catch { throw }

        # send telemetry ping if not disabled
        if (-not $script:Dir.DisableTelemetry) {
            Write-Debug "Sending Telemetry Ping"
            try {
                # Fire and forget, we don't care if it fails
                $req = [System.Net.Http.HttpRequestMessage]::new('HEAD','https://poshac.me/paping/')
                $null = $script:TelemetryClient.SendAsync($req)
            } catch {}
        }

        # Boulder's ACME implementation (at least on Staging) currently doesn't
        # quite follow the spec at this point. What I've observed is that the
        # response to the finalize request is indeed the order object and it appears
        # to have 'valid' status and a URL for the certificate. It skips the 'processing'
        # status entirely which we shouldn't rely on according to the spec.
        #
        # So we start polling the order directly and the first response comes back with
        # 'valid' status, but no certificate URL. Not sure if that means the previous
        # certificate URL was invalid. But we ultimately need to check for both 'valid'
        # status and a certificate URL to return.

        # now we poll
        for ($tries=1; $tries -le 30; $tries++) {

            $Order = $Order | Get-PAOrder -Refresh

            if ($Order.status -eq 'invalid') {
                try { throw "Order '$($Order.Name)' status is invalid." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            } elseif ($Order.status -eq 'valid' -and ![string]::IsNullOrWhiteSpace($Order.certificate)) {
                return
            } else {
                # According to spec, the only other statuses are pending, ready, or processing
                # which means we should wait more.
                Start-Sleep 2
            }

        }

        # If we're here, it means our poll timed out because we didn't return already. So throw.
        try { throw "Timed out waiting for order to become valid." }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

    }
}
