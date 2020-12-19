function Remove-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [switch]$RevokeCert,
        [switch]$Force
    )

    Begin {
        try {
            # Make sure we have an account configured
            if (-not ($acct = Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    Process {

        if (-not $MainDomain -and -not $Name) {
            try { throw "MainDomain and/or Name must be specified." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # check for a unique matching order
        if ($Name) {
            $order = Get-PAOrder -Name $Name
            if (-not $order) {
                Write-Error "No order found matching Name '$Name'."
                return
            }
        } else {
            $matchingOrders = @(Get-PAOrder -List | Where-Object { $_.MainDomain -eq $MainDomain })
            if ($matchingOrders.Count -eq 1) {
                $order = $matchingOrders
            } elseif ($matchingOrders.Count -ge 2) {
                # error because we can't be sure which object to affect
                Write-Error "Multiple orders found for MainDomain '$MainDomain'. Please specify Name as well."
                return
            } else {
                Write-Error "No order found matching MainDomain '$MainDomain'."
                return
            }
        }

        # revoke first, if asked
        if ($RevokeCert -and $order.status -eq 'valid') {
            $order | Set-PAOrder -RevokeCert -NoSwitch -Force:$Force.IsPresent
        }

        # confirm deletion unless -Force was used
        if (-not $Force) {
            $msg = "Deleting an order will also delete the certificate and key if they exist."
            $question = "Are you sure you wish to delete order '$($order.Name)'?"
            if (-not $PSCmdlet.ShouldContinue($question,$msg)) {
                Write-Verbose "Order deletion aborted for '$($order.Name)'."
                return
            }
        }

        Write-Verbose "Deleting order '$($order.Name)'"

        # delete the order's folder
        Remove-Item $order.Folder -Force -Recurse

        # unset the current order if it was this one
        if ($script:Order -and $script:Order.Name -eq $order.Name) {
            $order = $null
            Remove-Item (Join-Path $acct.Folder 'current-order.txt') -Force
            Import-PAConfig -Level 'Order'
        }

    }
}
