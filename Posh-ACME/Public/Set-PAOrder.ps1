function Set-PAOrder {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [switch]$Finalize
    )

    # Make sure we have an account configured
    if (!(Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    # check if we're switching orders
    if ($MainDomain -and $MainDomain -ne $script:Order.MainDomain) {

        # check for the order folder
        $orderFolder = Join-Path $script:AcctFolder $MainDomain.Replace('*','!')
        if (!(Test-Path $orderFolder -PathType Container)) {
            throw "No order folder found with MainDomain '$MainDomain'."
        }

        # try to load the order.json file
        $order = Get-Content (Join-Path $orderFolder 'order.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

        # save it
        $script:Order = $order
        $script:OrderFolder = $orderFolder
        $order.MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force

    } else {

        # just use the current order
        $order = $script:Order
        $MainDomain = $order.MainDomain
    }

    # check for a finalize request
    if ($Finalize) {

        Write-Verbose "Finalizing..."

    }

}
