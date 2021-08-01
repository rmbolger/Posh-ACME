function Update-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$SaveOnly
    )

    Begin {
        # make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        # grab the order from explicit parameters or the current memory copy
        if (-not $Name) {
            if (-not $script:Order) {
                Write-Warning "No ACME order configured. Run Set-PAOrder or specify a Name."
                return
            }
            $order = $script:Order
        } else {
            # return the current order if it matches the specified Name
            if ($script:Order -and $script:Order.Name -eq $Name) {
                $order = $script:Order
            } else {
                # or try and find it
                $order = Get-PAOrder -Name $Name
                if ($null -eq $order) {
                    Write-Warning "Specified order '$Name' was not found. Nothing to update."
                    return
                }
            }
        }

        if (-not $SaveOnly -and
            (-not $order.expires -or (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($order.expires))) )
        {

            Write-Debug "Refreshing order '$($order.Name)'"

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
                Write-Warning "ACME Exception querying order details for '$($order.Name)': $($_.Exception.Message)"
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
            Write-Debug "Order '$($order.Name)' is expired. Skipping server refresh."
        }

        # Make sure the order folder exists
        if (-not (Test-Path $order.Folder -PathType Container)) {
            New-Item -ItemType Directory -Path $order.Folder -Force -EA Stop | Out-Null
        }

        # Make a copy of the order so we can tweak it without messing up our existing copy
        $orderCopy = $order | ConvertTo-Json -Depth 10 | ConvertFrom-Json

        # Add an obfuscated PfxPass property to satisfy some requests for it to not be in plain text.
        $orderCopy | Add-Member 'PfxPassB64U' ($order.PfxPass | ConvertTo-Base64Url)

        # Save the copy to disk without the dynamic Name/Folder or plain text PfxPass
        $orderCopy | Select-Object -Exclude Name,Folder,PfxPass | ConvertTo-Json -Depth 10 |
            Out-File (Join-Path $order.Folder 'order.json') -Force -EA Stop
    }

}
