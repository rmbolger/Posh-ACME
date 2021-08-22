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
        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
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

    <#
    .SYNOPSIS
        Remove an ACME order from the local profile.

    .DESCRIPTION
        This function removes the reference to the order from the local profile which also removes any associated certificate and private key. It will not remove or cleanup copies of the certificate that have been exported or installed elsewhere. It will also not revoke the certificate unless -RevokeCert is used. The ACME server may retain a reference to the order until it decides to delete it.

    .PARAMETER MainDomain
        The primary domain for the order. For a SAN order, this was the first domain in the list when creating the order.

    .PARAMETER Name
        The name of the ACME order. This can be useful to distinguish between two orders that have the same MainDomain.

    .PARAMETER RevokeCert
        If specified and there is a currently valid certificate associated with the order, the certificate will be revoked before deleting the order. This is not required, but generally a good practice if the certificate is no longer being used.

    .PARAMETER Force
        If specified, interactive confirmation prompts will be skipped.

    .EXAMPLE
        Remove-PAOrder site1.example.com

        Remove the specified order without revoking the certificate.

    .EXAMPLE
        Get-PAOrder -List | Remove-PAOrder -RevokeCert -Force

        Remove all orders associated with the current account, revoke all certificates, and skip confirmation prompts.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
