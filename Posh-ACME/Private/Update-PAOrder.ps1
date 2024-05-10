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

        # Check for ARI renewal window updates if supported and there's an unexpired cert
        # https://www.ietf.org/archive/id/draft-ietf-acme-ari-03.html#name-getting-renewal-information
        if (-not $SaveOnly -and ($ariBase = (Get-PAServer).renewalInfo) -and
            $Order.CertExpires -and (Get-DateTimeOffsetNow) -lt [DateTimeOffset]::Parse($Order.CertExpires) )
        {
            Write-Verbose "Checking for updated renewal window via ARI"
            $queryParams = @{
                Uri = '{0}/{1}' -f $ariBase,($Order | Get-PACertificate).ARIId
                UserAgent = $script:USER_AGENT
                Headers = $script:COMMON_HEADERS
                ErrorAction = 'Stop'
                Verbose = $false
            }
            try {
                Write-Debug "GET $($queryParams.Uri)"
                $resp = Invoke-RestMethod @queryParams @script:UseBasic
                Write-Debug "Response:`n$($resp|ConvertTo-Json)"
            } catch { throw }

            if ($resp.suggestedWindow) {
                $renewAfter = $resp.suggestedWindow.start
                if ($renewAfter -ne $Order.RenewAfter) {
                    Write-Verbose "Updating renewal window to $renewAfter from ARI response"
                    $Order.RenewAfter = $renewAfter

                    # Warn if there's an explanation URL
                    if ($resp.explanationUrl) {
                        Write-Warning "The ACME Server has suggested an updated renewal window. Visit the following URL for more information:`n$($resp.explanationUrl)"
                    }
                }

                # Warn if the new window is in the past
                if ((Get-DateTimeOffsetNow) -gt [DateTimeOffset]::Parse($renewAfter)) {
                    Write-Warning "The ACME Server has indicated this order's certificate should be renewed AS SOON AS POSSIBLE."
                }
            }
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
