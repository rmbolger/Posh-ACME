function Get-PAOrder {
    [CmdletBinding()]
    [OutputType('PoshACME.PAOrder')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [switch]$Refresh
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
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
            $rawOrders = Get-ChildItem "$($script:AcctFolder)\*\order.json" | Get-Content -Raw
            $orders = $rawOrders | ConvertFrom-Json | Sort-Object MainDomain | ForEach-Object {

                # fix any dates that may have been parsed by PSCore's JSON serializer
                $_.expires = Repair-ISODate $_.expires
                $_.CertExpires = Repair-ISODate $_.CertExpires
                $_.RenewAfter = Repair-ISODate $_.RenewAfter

                # rename pre-4.x DnsPlugin parameter to Plugin
                if ('DnsPlugin' -in $_.PSObject.Properties.Name) {
                    $_ | Add-Member -MemberType NoteProperty -Name 'Plugin' -Value $_.DnsPlugin
                    $_.PSObject.Properties.Remove('DnsPlugin')
                }

                # de-obfuscate PfxPassB64U
                if ('PfxPassB64U' -in $_.PSObject.Properties.Name) {
                    $_ | Add-Member 'PfxPass' ($_.PfxPassB64U | ConvertFrom-Base64Url)
                    $_.PSObject.Properties.Remove('PfxPassB64U')
                }

                # insert the type name and send the results to the pipeline
                $_.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
                Write-Output $_
            }

            return $orders

        # Specific mode
        } else {

            if ($MainDomain) {

                # build the path to order.json
                $orderFile =  Join-Path ($MainDomain | Get-OrderFolder) 'order.json'

                # check for an order.json
                if (Test-Path $orderFile -PathType Leaf) {

                    Write-Debug "Loading PAOrder from disk"
                    $order = Get-Content $orderFile -Raw | ConvertFrom-Json
                    $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

                    # fix any dates that may have been parsed by PSCore's JSON serializer
                    $order.expires = Repair-ISODate $order.expires
                    $order.CertExpires = Repair-ISODate $order.CertExpires
                    $order.RenewAfter = Repair-ISODate $order.RenewAfter

                    # rename pre-4.x DnsPlugin parameter to Plugin
                    if ('DnsPlugin' -in $order.PSObject.Properties.Name) {
                        $order | Add-Member -MemberType NoteProperty -Name 'Plugin' -Value $order.DnsPlugin
                        $order.PSObject.Properties.Remove('DnsPlugin')
                    }

                    # de-obfuscate PfxPassB64U
                    if ('PfxPassB64U' -in $order.PSObject.Properties.Name) {
                        $order | Add-Member 'PfxPass' ($order.PfxPassB64U | ConvertFrom-Base64Url)
                        $order.PSObject.Properties.Remove('PfxPassB64U')
                    }

                } else {
                    return $null
                }

            } else {
                # just use the current one
                $order = $script:Order
            }

            if ($order -and $Refresh) {

                # update and then recurse to return the updated data
                Update-PAOrder $order.MainDomain
                return (Get-PAOrder $order.MainDomain)

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
