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
            if ($respObj.notBefore) {
                $Order | Add-Member 'notBefore' (Repair-ISODate $respObj.notBefore) -Force
            }
            if ($respObj.notAfter) {
                $Order | Add-Member 'notAfter' (Repair-ISODate $respObj.notAfter) -Force
            }

            # Work around GoDaddy ACME bug that fails to include the expires field when status = pending or valid.
            # https://www.rfc-editor.org/rfc/rfc8555.html#section-7.1.3
            # Check for notAfter and use [DateTime]::MaxValue if it doesn't exist.
            if ($Order.status -in 'pending','valid' -and -not $Order.expires) {
                if ($Order.notAfter) {
                    $Order.expires = $Order.notAfter
                } else {
                    $Order.expires = '9999-12-31T23:59:59Z' # [DateTime]::MaxValue.ToString('yyyy-MM-ddTHH:mm:ssZ')
                }
                Write-Warning "Invalid ACME response from CA. Order object has status $($Order.status) but is missing the 'expires' field which violates RFC8555 section 7.1.3. Please notify your CA. Using alternative value $($Order.expires)."
            }

        } elseif (-not $SaveOnly) {
            # Let's Encrypt no longer returns order details for expired orders
            # https://github.com/letsencrypt/boulder/commit/83aafd18842e093483d6701b92419ca8f7f1855b
            # So don't bother asking if we know it's already expired.
            Write-Debug "Order '$($Order.Name)' is expired. Skipping server refresh."
        }

        # Check for ARI renewal window updates if supported and there's an unexpired cert
        # https://www.ietf.org/archive/id/draft-ietf-acme-ari-03.html#name-getting-renewal-information
        $server = Get-PAServer
        if (-not $SaveOnly -and -not $server.DisableARI -and ($ariBase = $server.renewalInfo) -and
            $Order.CertExpires -and (Get-DateTimeOffsetNow) -lt [DateTimeOffset]::Parse($Order.CertExpires) )
        {
            Write-Verbose "Checking for updated renewal window via ARI"
            $cert = $Order | Get-PACertificate
            if ($cert.ARIId) {
                $queryParams = @{
                    Uri = '{0}/{1}' -f $ariBase,$cert.ARIId
                    UserAgent = $script:USER_AGENT
                    Headers = $script:COMMON_HEADERS
                    ErrorAction = 'Stop'
                    Verbose = $false
                }
                try {
                    Write-Debug "GET $($queryParams.Uri)"
                    $resp = Invoke-RestMethod @queryParams @script:UseBasic
                    Write-Debug "Response:`n$($resp|ConvertTo-Json)"
                } catch {
                    Write-Warning "ARI request failed."
                    $PSCmdlet.WriteError($_)
                }

                if ($resp.suggestedWindow) {
                    $renewAfter = Repair-ISODate $resp.suggestedWindow.start
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
            } else {
                Write-Warning "Unable to check ARI renewal window because cert object is missing ARIId value."
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
