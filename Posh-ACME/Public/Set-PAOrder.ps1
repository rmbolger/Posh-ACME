function Set-PAOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [switch]$RevokeCert
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount first."
        }
    }

    Process {

        # It's entirely possible that someone could pipe a bunch of domains to this function
        # and basically switch orders a bunch of times. But ultimately there's no harm in it,
        # so there's not reason to do anything about it.

        # check if we're switching orders
        if ($script:Order -and $MainDomain -ne $script:Order.MainDomain) {

            # refresh the cached copy
            Update-PAOrder $MainDomain

            Write-Debug "Switching to order $MainDomain"

            # save it as current
            $MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force

            # reload the cache from disk
            Import-PAConfig 'Order'

        }

    }





    <#
    .SYNOPSIS
        Set the current ACME order.

    .DESCRIPTION
        Allows you to switch between ACME orders for a particular account.

    .PARAMETER MainDomain
        The primary domain for the order. For a SAN order, this was the first domain in the list when creating the order.

    .EXAMPLE
        Set-PAOrder site1.example.com

        Switch to the specified domain's order.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
