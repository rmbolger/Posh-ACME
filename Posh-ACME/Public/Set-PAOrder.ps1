function Set-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [switch]$RevokeCert,
        [switch]$NoSwitch,
        [switch]$Force
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        # throw an error if there's no current order and no MainDomain
        # passed in
        if (!$script:Order -and !$MainDomain) {
            throw "No ACME order configured. Run New-PAOrder or specify a MainDomain."
        }

        # There are 3 types of calls the user might be making here.
        # - order switch
        # - order switch and revocation
        # - revocation only (possibly bulk via pipeline)
        # The default is to switch orders. So we have a -NoSwitch parameter to
        # indicate a non-switching revocation. But there's a chance they could forget
        # to use it for a bulk update. For now, we'll just let it happen and switch
        # to whatever order came through the pipeline last.

        if ($NoSwitch -and $MainDomain) {
            # This is a non-switching revocation, so grab a cached reference to the
            # order specified
            $order = Get-PAOrder $MainDomain

            if ($null -eq $order) {
                Write-Warning "Specified order for $MainDomain was not found. No changes made."
                return
            }

        } elseif (!$script:Order -or ($MainDomain -and ($MainDomain -ne $script:Order.MainDomain))) {
            # This is a definite order switch

            # refresh the cached copy
            Update-PAOrder $MainDomain

            Write-Debug "Switching to order $MainDomain"

            # save it as current
            $MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force

            # reload the cache from disk
            Import-PAConfig 'Order'

            # grab a local reference to the newly current order
            $order = $script:Order

        } else {
            # This is effectively a non-switching revocation because they didn't
            # specify a MainDomain. So just use the current order.
            $order = $script:Order
        }

        # revoke if necessary
        if ($RevokeCert) {

            # make sure the order is valid
            if ($order.status -ne 'valid') {
                Write-Warning "Unable to revoke certificate. Order for $($order.MainDomain) is not valid."
                return
            }

            # make sure the cert file actually exists
            $certFile = Join-Path (Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')) 'cert.cer'
            if (!(Test-Path $certFile -PathType Leaf)) {
                Write-Warning "Unable to revoke certificate. $certFile not found."
                return
            }

            # confirm revocation unless -Force was used
            if (!$Force) {
                if (!$PSCmdlet.ShouldContinue("Are you sure you wish to revoke $($order.MainDomain)?",
                "Revoking a certificate is irreversible and will immediately break any services using it.")) {
                    Write-Verbose "Revocation aborted for $($order.MainDomain)."
                    return
                }
            }

            Write-Verbose "Revoking certificate $($order.MainDomain)."

            # grab the cert file contents, strip the headers, and join the lines
            $certStart = -1; $certEnd = -1;
            $certLines = Get-Content $certFile
            for ($i=0; $i -lt $certLines.Count; $i++) {
                if ($certLines[$i] -eq '-----BEGIN CERTIFICATE-----') {
                    $certStart = $i + 1
                } elseif ($certLines[$i] -eq '-----END CERTIFICATE-----') {
                    $certEnd = $i - 1
                    break
                }
            }
            if ($certStart -lt 0 -or $certEnd -lt 0) {
                throw "Malformed certificate file. $certFile"
            }
            $certStr = $certLines[$certStart..$certEnd] -join '' | ConvertTo-Base64Url -FromBase64

            # build the header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:Dir.nonce;
                url   = $script:Dir.revokeCert;
            }

            $payloadJson = "{`"certificate`":`"$certStr`"}"

            # send the request
            try {
                $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            } catch { throw }
            Write-Debug "Response: $($response.Content)"

            # refresh the order
            Update-PAOrder $order.MainDomain

        }

    }





    <#
    .SYNOPSIS
        Set the current ACME order.

    .DESCRIPTION
        Switch between ACME orders on an account and/or revoke an order's certificate. Revoked certificate orders are not deleted and can be re-requested Submit-Renewal or New-PACertificate.

    .PARAMETER MainDomain
        The primary domain for the order. For a SAN order, this was the first domain in the list when creating the order.

    .PARAMETER RevokeCert
        If specified, a request will be sent to the associated ACME server to revoke the certificate on this order. Clients may wish to do this if the certificate is decommissioned or the private key has been compromised. A warning will be displayed if the order is not currently valid or the existing certificate file can't be found.

    .PARAMETER NoSwitch
        If specified, the currently selected order will not change. Useful primarily for bulk certificate revocation. This switch is ignored if no MainDomain is specified.

    .PARAMETER Force
        If specified, confirmation prompts for certificate revocation will be skipped.

    .EXAMPLE
        Set-PAOrder site1.example.com

        Switch to the specified domain's order.

    .EXAMPLE
        Set-PAORder -RevokeCert

        Revoke the current order's certificate.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
