function Submit-Renewal {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='Specific',Position=1,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
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
            try {
                if (-not (Get-PAAccount)) {
                    throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
                }
            }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {

        switch ($PSCmdlet.ParameterSetName) {

            'Specific' {

                # grab the order object
                $orderArgs = @{}
                if ($MainDomain) { $orderArgs.MainDomain = $MainDomain }
                if ($Name)       { $orderArgs.Name       = $Name }
                if (-not ($order = Get-PAOrder @orderArgs)) {
                    try { throw "No order found for the specified parameters." }
                    catch { $PSCmdlet.ThrowTerminatingError($_) }
                }

                # trigger an ARI check if supported
                if (-not (Get-PAServer).DisableARI -and (Get-PAServer).renewalInfo) {
                    Update-PAOrder -Order $order
                }

                # skip if the renewal window hasn't been reached and no -Force
                if (-not $Force -and $null -ne $order.RenewAfter -and (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($order.RenewAfter))) {
                    Write-Warning "Order '$($order.Name)' is not recommended for renewal yet. Use -Force to override."
                    return
                }

                # skip orders with no plugin (likely because they were created using custom processes)
                if ($null -eq $order.Plugin) {
                    Write-Warning "Skipping renewal for order '$($order.Name)' due to null plugin."
                    return
                }

                # skip orders with a Manual DNS plugin by default because they require interactivity
                if (-not $NoSkipManualDns -and 'Manual' -in @($order.Plugin)) {
                    Write-Warning "Skipping renewal for order '$($order.Name)' due to Manual DNS plugin. Use -NoSkipManualDns to avoid this."
                    return
                }

                Write-Verbose "Renewing certificate for order '$($order.Name)'"

                # If new PluginArgs were specified, store these now.
                if ($PluginArgs) {
                    Export-PluginArgs -Order $order -PluginArgs $PluginArgs
                }

                # Build the parameter list we're going to send to New-PACertificate
                $certParams = @{}

                if ([String]::IsNullOrWhiteSpace($order.CSRBase64Url)) {
                    # FromScratch param set
                    $certParams.Domain         = @($order.MainDomain);
                    if ($order.SANs.Count -gt 0) { $certParams.Domain += @($order.SANs) }
                    $certParams.CertKeyLength  = $order.KeyLength
                    $certParams.AlwaysNewKey   = $order.AlwaysNewKey
                    $certParams.OCSPMustStaple = $order.OCSPMustStaple
                    $certParams.FriendlyName   = $order.FriendlyName
                    $certParams.PfxPass        = $order.PfxPass
                    if (Test-WinOnly) { $certParams.Install = $order.Install }
                } else {
                    # FromCSR param set
                    $reqPath = Join-Path $order.Folder "request.csr"
                    $certParams.CSRPath = $reqPath
                }

                # common params
                $certParams.Name                = $order.Name
                $certParams.Plugin              = $order.Plugin
                $certParams.PluginArgs          = $order | Get-PAPluginArgs
                $certParams.DnsAlias            = $order.DnsAlias
                $certParams.UseSerialValidation = $order.UseSerialValidation
                $certParams.Force               = $Force.IsPresent
                $certParams.DnsSleep            = $order.DnsSleep
                $certParams.ValidationTimeout   = $order.ValidationTimeout
                $certParams.PreferredChain      = $order.PreferredChain
                $certParams.Profile             = $order.Profile

                if ($order.LifetimeDays -gt 0) { $certParams.LifetimeDays = $order.LifetimeDays }

                # now we just have to request a new cert using all of the old parameters
                New-PACertificate @certParams

                break
            }

            'AllOrders' {

                # get all existing orders on this account
                $orders = @(Get-PAOrder -List -Refresh)

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
                    Write-Verbose "No orders found for account $($script:Acct.id)."
                }

                break
            }

            'AllAccounts' {

                # save the current account so we can switch back when we're done
                $oldAcct = Get-PAAccount

                # get the list of valid accounts
                $accounts = Get-PAAccount -List -Status 'valid' -Refresh

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
                if ($oldAcct) { $oldAcct | Set-PAAccount }

                break
            }

        }

    }
}
