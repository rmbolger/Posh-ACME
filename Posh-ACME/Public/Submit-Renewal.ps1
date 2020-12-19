function Submit-Renewal {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='AllOrders',Mandatory)]
        [switch]$AllOrders,
        [Parameter(ParameterSetName='AllAccounts',Mandatory)]
        [switch]$AllAccounts,
        [switch]$Force,
        [switch]$NoSkipManualDns,
        [hashtable]$PluginArgs
    )

    Begin {
        # make sure we have an account if renewing all or a specific order
        if ($PSCmdlet.ParameterSetName -in 'Specific','AllOrders') {
            if (-not (Get-PAAccount)) {
                try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
    }

    Process {

        switch ($PSCmdlet.ParameterSetName) {

            'Specific' {

                # grab the order from explicit parameters or the current memory copy
                if (!$MainDomain) {
                    if (!$script:Order -or !$script:Order.MainDomain) {
                        try { throw "No ACME order configured. Run Set-PAOrder or specify a MainDomain." }
                        catch { $PSCmdlet.ThrowTerminatingError($_) }
                    }
                    $order = $script:Order
                } else {
                    # even if they specified the order explicitly, we may still be updating the
                    # "current" order. So figure that out because we don't want to read from disk
                    # if we don't have to
                    if ($script:Order -and $script:Order.MainDomain -and $script:Order.MainDomain -eq $MainDomain) {
                        $order = $script:Order
                    } else {
                        $order = Get-PAOrder $MainDomain
                    }
                }

                # skip if the renewal window hasn't been reached and no -Force
                if (!$Force -and $null -ne $order.RenewAfter -and (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($order.RenewAfter))) {
                    Write-Warning "Order for $($order.MainDomain) is not recommended for renewal yet. Use -Force to override."
                    return
                }

                # skip orders with no DNS plugin (likely because they were created using custom processes or HTTP validation)
                if ($null -eq $order.Plugin) {
                    Write-Warning "Skipping renewal for order $($order.MainDomain) due to null plugin."
                    return
                }

                # skip orders with a Manual DNS plugin by default because they require interactivity
                if (!$NoSkipManualDns -and 'Manual' -in @($order.Plugin)) {
                    Write-Warning "Skipping renewal for order $($order.MainDomain) due to Manual DNS plugin. Use -NoSkipManualDns to avoid this."
                    return
                }

                Write-Verbose "Renewing certificate for order $($order.MainDomain)"

                # Build the parameter list we're going to send to New-PACertificate
                $certParams = @{}
                if ([String]::IsNullOrWhiteSpace($order.CSRBase64Url)) {
                    $certParams.Domain = @($order.MainDomain);
                    if ($order.SANs.Count -gt 0) { $certParams.Domain += @($order.SANs) }
                    $certParams.OCSPMustStaple = $order.OCSPMustStaple
                    $certParams.FriendlyName = $order.FriendlyName
                    $certParams.PfxPass = $order.PfxPass
                    if (Test-WinOnly) { $certParams.Install = $order.Install }
                } else {
                    $reqPath = Join-Path ($order | Get-OrderFolder) "request.csr"
                    $certParams.CSRPath = $reqPath
                }
                $certParams.Plugin = $order.Plugin

                # If new PluginArgs were specified, store these now.
                if ($PluginArgs) {
                    Export-PluginArgs $order.MainDomain $order.Plugin $PluginArgs
                }

                $certParams.PluginArgs = Get-PAPluginArgs $order.MainDomain
                $certParams.DnsAlias = $order.DnsAlias
                $certParams.Force = $Force.IsPresent
                $certParams.DnsSleep = $order.DnsSleep
                $certParams.ValidationTimeout = $order.ValidationTimeout

                # now we just have to request a new cert using all of the old parameters
                New-PACertificate @certParams

                break
            }

            'AllOrders' {

                # get the list of all completed orders which should have a non-null RenewAfter property
                $orders = @(Get-PAOrder -List -Refresh | Where-Object { $null -ne $_.RenewAfter })

                # remove the ones that aren't ready for renewal unless -Force was used
                if (!$Force) {
                    $orders = @($orders | Where-Object { (Get-DateTimeOffsetNow) -ge ([DateTimeOffset]::Parse($_.RenewAfter)) })
                }

                if ($orders.Count -gt 0) {

                    $renewParams = @{
                        Force = $Force.IsPresent
                        NoSkipManualDns = $NoSkipManualDns.IsPresent
                    }

                    # If new PluginArgs were specified use them
                    if ($PluginArgs) {
                        $renewParams.PluginArgs = $PluginArgs
                    }

                    # recurse to renew these orders
                    $orders | Submit-Renewal @renewParams

                } else {
                    Write-Verbose "No renewable orders found for account $($script:Acct.id)."
                }

                break
            }

            'AllAccounts' {

                # save the current account so we can switch back when we're done
                $oldAcct = Get-PAAccount

                # get the list of valid accounts
                $accounts = Get-PAAccount -List -Refresh | Where-Object { $_.status -eq 'valid' }

                foreach ($acct in $accounts) {

                    # set it as current
                    $acct | Set-PAAccount

                    $renewParams = @{
                        AllOrders = $true
                        Force = $Force.IsPresent
                        NoSkipManualDns = $NoSkipManualDns.IsPresent
                    }

                    # If new PluginArgs were specified use them
                    if ($PluginArgs) {
                        $renewParams.PluginArgs = $PluginArgs
                    }

                    # recurse to renew all orders on it
                    Submit-Renewal @renewParams
                }

                # restore the old current account
                if ($oldAcct) { $oldAccount | Set-PAAccount }

                break
            }

        }

    }





    <#
    .SYNOPSIS
        Renew one or more certificates.

    .DESCRIPTION
        This function allows you to renew one more more previously completed certificate orders. You can choose to renew a specific order or set of orders, all orders for the current account, or all orders for all accounts.

    .PARAMETER MainDomain
        The primary domain associated with an order. This is the domain that goes in the certificate's subject.

    .PARAMETER AllOrders
        If specified, renew all valid orders on the current account. Orders that have not reached the renewal window will be skipped unless -Force is used.

    .PARAMETER AllAccounts
        If specified, renew all valid orders on all valid accounts in this profile. Orders that have not reached the renewal window will be skipped unless -Force is used.

    .PARAMETER Force
        If specified, an order that hasn't reached its renewal window will not throw an error and will not be skipped when using either of the -All parameters.

    .PARAMETER NoSkipManualDns
        If specified, orders that utilize the Manual DNS plugin will not be skipped and user interaction may be required to complete the process. Otherwise, orders that utilize the Manual DNS plugin will be skipped.

    .PARAMETER PluginArgs
        A hashtable containing an updated set of plugin arguments to use with the renewal. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .EXAMPLE
        Submit-Renewal

        Renew the current order on the current account.

    .EXAMPLE
        Submit-Renewal -Force

        Renew the current order on the current account even if it hasn't reached its suggested renewal window.

    .EXAMPLE
        Submit-Renewal -AllOrders

        Renew all valid orders on the current account that have reached their suggested renewal window.

    .EXAMPLE
        Submit-Renewal -AllAccounts

        Renew all valid orders on all valid accounts that have reached their suggested renewal window.

    .EXAMPLE
        Submit-Renewal site1.example.com -Force

        Renew the order for the specified site regardless of its renewal window.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    .LINK
        Get-PAOrder

    #>
}
