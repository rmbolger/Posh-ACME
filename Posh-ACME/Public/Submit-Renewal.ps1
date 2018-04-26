function Submit-Renewal {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='AllOrders',Mandatory)]
        [switch]$AllOrders,
        [Parameter(ParameterSetName='AllAccounts',Mandatory)]
        [switch]$AllAccounts,
        [switch]$NewKey,
        [switch]$Force,
        [switch]$NoSkipManualDns
    )

    Begin {
        # import existing plugin args if we're only dealing with the current account
        if ($PSCmdlet.ParameterSetName -in 'Specific','AllOrders') {

            # Make sure we have an account configured
            if (!(Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }

            $pluginArgs = Import-PluginArgs
        }
    }

    Process {

        switch ($PSCmdlet.ParameterSetName) {

            'Specific' {

                # grab the order from explicit parameters or the current memory copy
                if (!$MainDomain) {
                    if (!$script:Order -or !$script:Order.MainDomain) {
                        throw "No ACME order configured. Run Set-PAOrder or specify a MainDomain."
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

                # error if the order isn't already valid because renewals presume you've successfully
                # completed the order already
                if ($order.status -ne 'valid') {
                    throw "Order for $($order.MainDomain) is either invalid or was never completed and can't currently be renewed."
                }

                # error if the renewal window hasn't been reached and no -Force
                if (!$Force -and (Get-Date) -lt (Get-Date $order.RenewAfter)) {
                    throw "Order for $($order.MainDomain) is not recommended for renewal yet. Use -Force to override."
                }

                # skip orders with a Manual DNS plugin
                if (!$NoSkipManualDns -and 'Manual' -in @($order.DnsPlugin)) {
                    Write-Warning "Skipping renewal for order $($order.MainDomain) due to Manual DNS plugin. Use -NoSkipManualDns to avoid this."
                    return
                }

                Write-Verbose "Renewing certificate for order $($order.MainDomain)"

                # Build the parameter list we're going to send to New-PACertificate
                $certParams = @{}
                $certParams.Domain = @($order.MainDomain);
                if ($order.SANs.Count -gt 0) { $certParams.Domain += @($order.SANs) }
                $certParams.NewCertKey = $NewKey.IsPresent
                $certParams.DnsPlugin = $order.DnsPlugin
                $certParams.PluginArgs = $pluginArgs
                $certParams.OCSPMustStaple = $order.OCSPMustStaple
                $certParams.Force = $Force.IsPresent
                $certParams.DnsSleep = $order.DnsSleep
                $certParams.ValidationTimeout = $order.ValidationTimeout

                # now we just have to request a new cert using all of the old parameters
                New-PACertificate @certParams

                break
            }

            'AllOrders' {

                # get the list of all completed (valid) orders
                $orders = Get-PAOrder -List -Refresh | Where-Object { $_.status -eq 'valid' }

                # remove the ones that are ready for renewal unless -Force was used
                if (!$Force) {
                    $orders = $orders | Where-Object { (Get-Date) -ge (Get-Date $_.RenewAfter) }
                }

                if ($orders.Count -gt 0) {
                    # recurse to renew these orders
                    $orders | Submit-Renewal -NewKey:$NewKey.IsPresent -Force:$Force.IsPresent
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

                    # recurse to renew all orders on it
                    Submit-Renewal -AllOrders -NewKey:$NewKey.IsPresent -Force:$Force.IsPresent
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
        If specified, renew all valid orders on the current account. Orders that have not reached their RenewAfter date will be skipped unless -Force is used.

    .PARAMETER AllAccounts
        If specified, renew all valid orders on all valid accounts in this profile. Orders that have not reached their RenewAfter date will be skipped unless -Force is used.

    .PARAMETER NewKey
        If specified, a new private key will be generated for the certificate renewal. Otherwise, the old key is re-used. This is useful if you believe the current key has been compromised.

    .PARAMETER Force
        If specified, an order that hasn't reached its RenewAfter date will not throw an error and will not be skipped when using either of the -All parameters.

    .PARAMETER NoSkipManualDns
        If specified, orders that utilize the Manual DNS plugin will not be skipped and user interaction may be required to complete the process. Otherwise, orders that utilize the Manual DNS plugin will be skipped.

    .EXAMPLE
        Submit-Renewal

        Renew the current order on the current account.

    .EXAMPLE
        Submit-Renewal -Force

        Renew the current order on the current account even if it hasn't reached its suggested RenewAfter date.

    .EXAMPLE
        Submit-Renewal -AllOrders

        Renew all valid orders on the current account that have reached their suggested RenewAfter date.

    .EXAMPLE
        Submit-Renewal -AllAccounts

        Renew all valid orders on all valid accounts that have reached their suggested RenewAfter date.

    .EXAMPLE
        Submit-Renewal site1.example.com -NewKey -Force

        Renew the order for the specified site regardless of its RenewAfter date and generate a new private key.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    .LINK
        Get-PAOrder

    #>
}
