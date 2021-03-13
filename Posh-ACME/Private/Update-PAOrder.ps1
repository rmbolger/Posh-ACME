function Update-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [switch]$SaveOnly
    )

    Begin {
        # make sure we have an account configured
        if (!($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        # grab the order from explicit parameters or the current memory copy
        if (!$MainDomain) {
            if (!$script:Order -or !$script:Order.MainDomain) {
                Write-Warning "No ACME order configured. Run Set-PAOrder or specify a MainDomain."
                return
            }
            $order = $script:Order
        } else {
            # even if they specified the order explicitly, we may still be updating the
            # "current" order. So figure that out and set a flag for later.
            if ($script:Order -and $script:Order.MainDomain -and $script:Order.MainDomain -eq $MainDomain) {
                $order = $script:Order
            } else {
                $order = Get-PAOrder $MainDomain
                if ($null -eq $order) {
                    Write-Warning "Specified order for $MainDomain was not found. Nothing to update."
                    return
                }
            }
        }

        if (-not $SaveOnly -and
            (-not $order.expires -or (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($order.expires))) )
        {

            Write-Debug "Refreshing order $($order.MainDomain)"

            # build the header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:Dir.nonce;
                url   = $order.location;
            }

            # send the request
            try {
                $response = Invoke-ACME $header ([String]::Empty) $acct -EA Stop
            } catch [AcmeException] {
                Write-Warning "ACME Exception querying order details for $($order.MainDomain): $($_.Exception.Message)"
                return
            }

            $respObj = $response.Content | ConvertFrom-Json

            # update the things that could have changed
            $order.status = $respObj.status
            $order.expires = Repair-ISODate $respObj.expires
            if ($respObj.certificate) {
                $order.certificate = $respObj.certificate
            }
        } elseif (-not $SaveOnly) {
            # Let's Encrypt no longer returns order details for expired orders
            # https://github.com/letsencrypt/boulder/commit/83aafd18842e093483d6701b92419ca8f7f1855b
            # So don't bother asking if we know it's already expired.
            Write-Debug "Order $($order.MainDomain) is expired. Skipping server refresh."
        }

        # Save the order to disk
        # We're going to obfuscate the PfxPass property to satisfy some requests
        # to not have it in plain text.
        $orderFolder = $order | Get-OrderFolder
        if (-not (Test-Path $orderFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $orderFolder -Force -EA Stop | Out-Null
        }

        # make a copy of the order so we can tweak it without messing up
        # our existing copy and swap PfxPass for PfxPassB64U
        $orderCopy = $order | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $orderCopy | Add-Member 'PfxPassB64U' ($order.PfxPass | ConvertTo-Base64Url)
        $orderCopy.PSObject.Properties.Remove('PfxPass')

        $orderCopy | ConvertTo-Json -Depth 10 | Out-File (Join-Path $orderFolder 'order.json') -Force -EA Stop
    }

}
