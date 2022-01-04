function Update-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [switch]$SaveOnly
    )

    Begin {
        # make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        if (-not $SaveOnly -and
            (-not $Order.expires -or (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($Order.expires))) )
        {

            Write-Debug "Refreshing order '$($Order.Name)'"

            # build the header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:Dir.nonce;
                url   = $Order.location;
            }

            # send the request
            try {
                $response = Invoke-ACME $header ([String]::Empty) $acct -EA Stop
            } catch [AcmeException] {
                Write-Warning "ACME Exception querying order details for '$($Order.Name)': $($_.Exception.Message)"
                return
            }

            $respObj = $response.Content | ConvertFrom-Json

            # update the things that could have changed
            $Order | Add-Member 'status' $respObj.status -Force
            $Order | Add-Member 'expires' (Repair-ISODate $respObj.expires) -Force
            if ($respObj.certificate) {
                $Order | Add-Member 'certificate' $respObj.certificate -Force
            }

        } elseif (-not $SaveOnly) {
            # Let's Encrypt no longer returns order details for expired orders
            # https://github.com/letsencrypt/boulder/commit/83aafd18842e093483d6701b92419ca8f7f1855b
            # So don't bother asking if we know it's already expired.
            Write-Debug "Order '$($Order.Name)' is expired. Skipping server refresh."
        }

        # Make sure the order folder exists
        if (-not (Test-Path $Order.Folder -PathType Container)) {
            New-Item -ItemType Directory -Path $Order.Folder -Force -EA Stop | Out-Null
        }

        # Make a copy of the order so we can tweak it without messing up our existing copy
        $orderCopy = $Order | ConvertTo-Json -Depth 10 | ConvertFrom-Json

        # Add an obfuscated PfxPass property to satisfy some requests for it to not be in plain text.
        $orderCopy | Add-Member 'PfxPassB64U' ($Order.PfxPass | ConvertTo-Base64Url)

        # Save the copy to disk without the dynamic Name/Folder or plain text PfxPass
        $orderCopy | Select-Object -Property * -ExcludeProperty Name,Folder,PfxPass |
            ConvertTo-Json -Depth 10 |
            Out-File (Join-Path $Order.Folder 'order.json') -Force -EA Stop
    }

}
