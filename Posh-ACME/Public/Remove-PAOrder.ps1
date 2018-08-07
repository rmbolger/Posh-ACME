function Remove-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [switch]$RevokeCert,
        [switch]$Force
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        # grab a copy of the order
        if (!($order = Get-PAOrder $MainDomain)) {
            Write-Warning "Specified order for $MainDomain was not found."
            return
        }

        # revoke first, if asked
        if ($RevokeCert -and $order.status -eq 'valid') {
            $order | Set-PAOrder -RevokeCert -NoSwitch -Force:$Force.IsPresent
        }

        # confirm deletion unless -Force was used
        if (!$Force) {
            $msg = "Deleting an order will also delete the certificate and key if they exist."
            $question = "Are you sure you wish to delete $($order.MainDomain)?"
            if (!$PSCmdlet.ShouldContinue($question,$msg)) {
                Write-Verbose "Order deletion aborted for $($order.MainDomain)."
                return
            }
        }

        Write-Verbose "Deleting order for $($order.MainDomain)"

        # delete the order's folder
        $orderFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
        Remove-Item $orderFolder -Force -Recurse

        # unset the current order if it was this one
        if ($script:Order -and $script:Order.MainDomain -eq $order.MainDomain) {
            $script:Order = $null
            $script:OrderFolder = $null
            $order = $null

            Remove-Item (Join-Path $script:AcctFolder 'current-order.txt') -Force
        }

    }

    <#
    .SYNOPSIS
        Remove an ACME order from the local profile.

    .DESCRIPTION
        This function removes the reference to the order from the local profile which also removes any associated certificate and private key. It will not remove or cleanup copies of the certificate that have been exported or installed elsewhere. It will also not revoke the certificate unless -RevokeCert is used. The ACME server may retain a reference to the order until it decides to delete it.

    .PARAMETER MainDomain
        The primary domain for the order. For a SAN order, this was the first domain in the list when creating the order.

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
