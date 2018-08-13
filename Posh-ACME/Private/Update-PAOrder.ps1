function Update-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [switch]$SaveOnly
    )

    Begin {
        # make sure we have an account configured
        if (!(Get-PAAccount)) {
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
            $UpdatingCurrent = $true
        } else {
            # even if they specified the order explicitly, we may still be updating the
            # "current" order. So figure that out and set a flag for later.
            if ($script:Order -and $script:Order.MainDomain -and $script:Order.MainDomain -eq $MainDomain) {
                $UpdatingCurrent = $true
                $order = $script:Order
            } else {
                $UpdatingCurrent = $false
                $order = Get-PAOrder $MainDomain
                if ($null -eq $order) {
                    Write-Warning "Specified order for $MainDomain was not found. Nothing to update."
                    return
                }
            }
        }

        if (!$SaveOnly) {
            Write-Debug "Refreshing order $($order.MainDomain)"

            # we can request the order info via an anonymous GET request
            try {
                $response = Invoke-WebRequest $order.location -EA Stop -Verbose:$false @script:UseBasic
            } catch { throw }
            Write-Debug "Response: $($response.Content)"

            $respObj = $response.Content | ConvertFrom-Json

            # update the things that could have changed
            $order.status = $respObj.status
            $order.expires = $respObj.expires
            if ($respObj.certificate) {
                $order.certificate = $respObj.certificate
            }
        }

        # save it to disk
        $orderFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
        $order | ConvertTo-Json | Out-File (Join-Path $orderFolder 'order.json') -Force
    }

}
