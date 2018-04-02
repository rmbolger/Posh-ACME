function Get-PAOrder {
    [OutputType('PoshACME.PAOrder')]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [switch]$Refresh
    )

    # Make sure we have an account configured
    if (!(Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    # List mode
    if ('List' -eq $PSCmdlet.ParameterSetName) {

        # read the contents of each order's order.json
        $rawOrders = Get-ChildItem "$($script:AcctFolder)\*\order.json" | Get-Content -Raw
        $rawOrders | ConvertFrom-Json | Sort-Object MainDomain | ForEach-Object {

            # insert the type so it displays properly
            $_.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

            # update the data from the server
            if ($Refresh -and $_.status -ne 'invalid') { Update-PAOrder $_ }
            Write-Output $_
        }

    # Specific mode
    } else {

        if ($MainDomain) {

            # build the path to the order file
            $domainFolder = $MainDomain.Replace('*','!')
            $orderFile = "$($script:AcctFolder)\$domainFolder\order.json"

            # check for an order.json
            if (Test-Path $orderFile -PathType Leaf) {
                $order = Get-ChildItem $orderFile | Get-Content -Raw | ConvertFrom-Json
                $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
            }

        } else {
            # just use the current one
            $order = $script:Order
        }

        if ($order) {
            # update the data from the server if requested
            if ($Refresh) { Update-PAOrder $order }

            return $order
        }

    }

}
