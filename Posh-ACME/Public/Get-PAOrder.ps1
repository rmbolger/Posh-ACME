function Get-PAOrder {
    [CmdletBinding()]
    param(
        [switch]$List,
        [switch]$Refresh
    )

    # Make sure we have an account configured
    if (!(Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    if ($List) {
        # read the contents of each order's order.json
        Get-ChildItem "$($script:AcctFolder)\*\order.json" | Get-Content -Raw |
            ConvertFrom-Json | Sort-Object MainDomain | ForEach-Object {

                $_.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

                # update the data from the server
                if ($Refresh -and $_.status -ne 'invalid') { Update-PAOrder $_ }
                Write-Output $_
            }
    } else {

        $order = $script:Order

        # update the data from the server if requested
        if ($Refresh) { Update-PAOrder $order }

        $script:Order
    }

}
