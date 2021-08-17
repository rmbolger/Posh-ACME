function Get-PAOrder {
    [CmdletBinding()]
    [OutputType('PoshACME.PAOrder')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='Specific',ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [switch]$Refresh
    )

    Begin {
        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {

        # List mode
        if ('List' -eq $PSCmdlet.ParameterSetName) {

            # update from the server first if requested
            if ($Refresh) {
                Write-Debug "Refreshing orders"
                Get-PAOrder -List | Update-PAOrder
            }

            # read the contents of each order's order.json
            Write-Debug "Loading PAOrder list from disk"
            $orders = Get-ChildItem (Join-Path $acct.Folder '\*\order.json') | ForEach-Object {

                # parse the json
                $order = $_ | Get-Content -Raw | ConvertFrom-Json

                # fix any dates that may have been parsed by PSCore's JSON serializer
                $order.expires     = Repair-ISODate $order.expires
                $order.CertExpires = Repair-ISODate $order.CertExpires
                $order.RenewAfter  = Repair-ISODate $order.RenewAfter

                # rename pre-4.x DnsPlugin parameter to Plugin
                if ('DnsPlugin' -in $order.PSObject.Properties.Name) {
                    $order | Add-Member 'Plugin' $order.DnsPlugin -Force
                    $order.PSObject.Properties.Remove('DnsPlugin')
                }

                # de-obfuscate PfxPassB64U
                if ('PfxPassB64U' -in $order.PSObject.Properties.Name) {
                    $order | Add-Member 'PfxPass' ($order.PfxPassB64U | ConvertFrom-Base64Url) -Force
                    $order.PSObject.Properties.Remove('PfxPassB64U')
                }

                # add the dynamic Name and Folder property
                $order | Add-Member 'Name' $_.Directory.Name -Force
                $order | Add-Member 'Folder' $_.Directory.FullName -Force

                # insert the type name and send the results to the pipeline
                $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
                Write-Output $order
            }

            return ($orders | Sort-Object MainDomain)

        # Specific mode
        } else {

            if ($MainDomain) {

                # filter the normal list output
                $matchingOrders = Get-PAOrder -List | Sort-Object -Descending expires |
                    Where-Object { $_.MainDomain -eq $MainDomain }

                # if Name was also specified, there should only ever be 0 or 1 match, otherwise
                # pick the first match to retain script compatibility with 4.6 and earlier.
                if ($Name) {
                    $order = $matchingOrders | Where-Object { $_.Name -eq $Name }
                } else {
                    $order = $matchingOrders | Select-Object -First 1
                }

            } elseif ($Name) {
                # try to match the name which should be unique
                $order = Get-PAOrder -List | Where-Object { $_.Name -eq $Name }

            } else {
                # just use the current one
                $order = $script:Order
            }

            if ($order -and $Refresh) {

                # update and then recurse to return the updated data
                Update-PAOrder $order
                Get-PAOrder -List | Where-Object { $_.Name -eq $order.Name }

            } else {
                # just return whatever we've got
                return $order
            }

        }
    }





    <#
    .SYNOPSIS
        Get ACME order details.

    .DESCRIPTION
        Returns details such as Domains, key length, expiration, and status for one or more ACME orders previously created.

    .PARAMETER MainDomain
        The primary domain associated with the order. This is the domain that goes in the certificate's subject.

    .PARAMETER Name
        The name of the ACME order. This can be useful to distinguish between two orders that have the same MainDomain.

    .PARAMETER List
        If specified, the details for all orders will be returned.

    .PARAMETER Refresh
        If specified, any order details returned will be freshly queried from the ACME server. Otherwise, cached details will be returned.

    .EXAMPLE
        Get-PAOrder

        Get cached ACME order details for the currently selected order.

    .EXAMPLE
        Get-PAOrder site.example.com

        Get cached ACME order details for the specified domain.

    .EXAMPLE
        Get-PAOrder -List

        Get all cached ACME order details.

    .EXAMPLE
        Get-PAOrder -Refresh

        Get fresh ACME order details for the currently selected order.

    .EXAMPLE
        Get-PAOrder -List -Refresh

        Get fresh ACME order details for all orders.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Set-PAOrder

    .LINK
        New-PAOrder

    #>
}
