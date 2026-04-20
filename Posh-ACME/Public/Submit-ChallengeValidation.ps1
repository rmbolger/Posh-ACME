function Submit-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # Here's the overview of this function's purpose:
    # - publish challenges for any pending authorizations in the Order
    # - notify ACME server to validate those challenges
    # - wait until the validations are complete (good or bad)
    # - unpublish the challenges that were published
    # - return the updated order if successful, otherwise throw

    Begin {
        try {
            # make sure an account exists
            if (-not ($acct = Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }
            # make sure it's valid
            if ($acct.status -ne 'valid') {
                throw "Account status is $($acct.status)."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    Process {

        # make sure any order passed in is actually associated with the account
        # or if no order was specified, that there's a current order.
        if (-not $Order) {
            if (-not ($Order = Get-PAOrder)) {
                try { throw "No Order parameter specified and no current order selected. Try running Set-PAOrder first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        } elseif ($Order.Name -notin (Get-PAOrder -List).Name) {
            Write-Error "Order '$($Order.Name)' was not found in the current account's order list."
            return
        }

        # make sure the order has a valid state for this function
        if ($Order.status -eq 'invalid') {
            Write-Error "Order '$($Order.Name)' status is invalid. Unable to continue."
            return
        }
        elseif ($Order.status -in 'valid','processing') {
            Write-Warning "The server has already issued or is processing a certificate for order '$($Order.Name)'."
            return
        }
        elseif ($Order.status -eq 'ready') {
            Write-Warning "Order '$($Order.Name)' has already completed challenge validation and is awaiting finalization."
            return
        }


        # The only order status left is 'pending'. This means that at least one
        # authorization hasn't been validated yet according to
        # https://tools.ietf.org/html/rfc8555#section-7.1.6
        # So we're going to check all of the authorization statuses and publish
        # records for any that are still pending.

        $allAuths = @($Order | Get-PAAuthorization)

        # fill out the order's Plugin attribute so there's a value for each authorization
        if (-not $Order.Plugin) {
            Write-Warning "No plugin found associated with order. Defaulting to Manual."
            $Order.Plugin = @('Manual') * $allAuths.Count
        } elseif ($Order.Plugin.Count -lt $allAuths.Count) {
            $lastPlugin = $Order.Plugin[-1]
            Write-Warning "Fewer Plugin values than names in the order. Using $lastPlugin for the rest."
            $Order.Plugin += @($lastPlugin) * ($allAuths.Count-$Order.Plugin.Count)
        }
        Write-Debug "Plugin: $($Order.Plugin -join ',')"

        # fill out the order's DnsAlias attribute so there's a value for each authorization
        if (-not $Order.DnsAlias) {
            # no alias means they should all just be empty
            $Order.DnsAlias = @('') * $allAuths.Count
        } elseif ($Order.DnsAlias.Count -lt $allAuths.Count) {
            $lastAlias = $Order.DnsAlias[-1]
            Write-Warning "Fewer DnsAlias values than names in the order. Using $lastAlias for the rest."
            $Order.DnsAlias += @($lastAlias) * ($allAuths.Count-$Order.DnsAlias.Count)
        }
        Write-Debug "DnsAlias: $($Order.DnsAlias -join ',')"

        # import existing args
        $PluginArgs = Get-PAPluginArgs -Name $Order.Name

        # loop through the authorizations looking for challenges to publish and validate
        $published = @()
        $toValidate = @()
        $sleepForPersist = $false
        for ($i=0; $i -lt $allAuths.Count; $i++) {

            $pubParams = $null
            $auth = $allAuths[$i]
            if ($auth.status -eq 'pending') {

                # Determine which challenge to publish based on the plugin type and check
                # for any alternate DNS challenge preference specified in the order
                $chalType = $script:Plugins.($Order.Plugin[$i]).ChallengeType
                if ($chalType -eq 'dns-01' -and $Order.DnsVariant -and $Order.DnsVariant -ne 'dns-01') {
                    $chalType = $Order.DnsVariant
                    Write-Verbose "Using alternate DNS challenge type '$chalType' for $($auth.fqdn) based on order preference."
                }
                $challenge = $auth.challenges | Where-Object { $_.type -eq $chalType }
                if (-not $challenge) {
                    try {
                        throw "$($auth.fqdn) authorization contains no challenges that match $chalType"
                    } catch { $PSCmdlet.ThrowTerminatingError($_) }
                }

                if ($chalType -eq 'dns-persist-01') {
                    # publish the persist record if requested
                    if ($PluginArgs.PublishPersist) {
                        # Sanitize the account URI for draft-00 challenges until implementations support the newer draft and include it.
                        if (-not $challenge.accounturi) {
                            Write-Warning "dns-persist-01 challenge for $($auth.DNSId) is missing accounturi. Using account URI from account object instead."
                            $challenge | Add-Member accounturi $acct.location -Force
                        }
                        $issuer = Get-IssuerFromChallenge $challenge
                        if (-not $issuer) {
                            try {
                                throw "Unable to determine issuer domain name from dns-persist-01 challenge."
                            } catch { $PSCmdlet.ThrowTerminatingError($_) }
                        }
                        $pubParams = @{
                            Domain = $auth.DNSId
                            AccountUri = $challenge.accounturi
                            IssuerDomainName = $issuer
                            Plugin = $Order.Plugin[$i]
                            PluginArgs = $PluginArgs
                        }
                        try {
                            Publish-DnsPersistChallenge @pubParams
                            $sleepForPersist = $true
                        } catch { throw }
                    }
                } else {
                    # publish standard challenge
                    $pubParams = @{
                        Domain = $auth.DNSId
                        Account = $acct
                        Token = $challenge.token
                        Plugin = $Order.Plugin[$i]
                        PluginArgs = $PluginArgs
                        DnsAlias = $Order.DnsAlias[$i]
                        DnsVariant = $Order.DnsVariant
                    }
                    try {
                        Publish-Challenge @pubParams
                        # save the params to unpublish later
                        $published += $pubParams
                    } catch { throw }
                }

                if ($Order.UseSerialValidation) {
                    # save and validate the challenge before moving on to the next
                    try {
                        if ($chalType -ne 'dns-persist-01') {
                            Save-Challenge -Plugin $pubParams.Plugin -PluginArgs $PluginArgs
                        }

                        # sleep while DNS changes propagate if a DNS challenge was published
                        if ($chalType -like 'dns-*' -and $Order.DnsSleep -gt 0 -and $pubParams) {
                            Write-Verbose "Sleeping for $($Order.DnsSleep) seconds while DNS change(s) propagate"
                            Start-SleepProgress $Order.DnsSleep -Activity "Waiting for DNS to propagate"
                        }

                        # ask the server to validate the challenge
                        Write-Verbose "Requesting challenge validation"
                        $challenge.url | Send-ChallengeAck -Account $acct

                        # and wait for it to succeed or fail
                        Wait-AuthValidation $auth.location $Order.ValidationTimeout
                    }
                    catch {
                        $PSCmdlet.ThrowTerminatingError($_)
                    }
                    finally {
                        # always try to cleanup non-persistent challenges
                        if ($chalType -ne 'dns-persist-01') {
                            Unpublish-Challenge @pubParams
                            Save-Challenge -Plugin $pubParams.Plugin -PluginArgs $PluginArgs
                        }
                    }
                } else {
                    # save the details we'll need later for batch validation
                    $toValidate += @{
                        chalType = $chalType
                        chalUrl = $challenge.url
                        authUrl = $auth.location
                    }
                }

            } elseif ($auth.status -eq 'valid') {
                # skip ones that are already valid
                Write-Verbose "$($auth.fqdn) authorization is already valid"
                continue
            } else {
                #status invalid, revoked, deactivated, or expired
                try {
                    throw "$($auth.fqdn) authorization status is '$($auth.status)'. Create a new order and try again."
                } catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }

        if ($Order.UseSerialValidation) {
            # nothing left to do
            return
        }

        try {
            # save the non-persistent challenges we published
            if ($published.Count -gt 0) {
                $published.plugin | Sort-Object -Unique | ForEach-Object {
                    Save-Challenge -Plugin $_ -PluginArgs $PluginArgs
                }
            }

            # sleep while DNS changes propagate if there were DNS challenges published
            if ($Order.DnsSleep -gt 0 -and $toValidate.chalType -match '^dns-' -and
                ($published.Count -gt 0 -or $sleepForPersist)
            ) {
                Write-Verbose "Sleeping for $($Order.DnsSleep) seconds while DNS change(s) propagate"
                Start-SleepProgress $Order.DnsSleep -Activity "Waiting for DNS to propagate"
            }

            # ask the server to validate the challenges
            Write-Verbose "Requesting challenge validations"
            $toValidate.chalUrl | Send-ChallengeAck -Account $acct

            # and wait for them to succeed or fail
            Wait-AuthValidation @($toValidate.authUrl) $Order.ValidationTimeout
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        finally {
            # always try to cleanup non-persistent challenges
            $published | ForEach-Object {
                Unpublish-Challenge @_
            }

            # save the cleanup changes
            $published.plugin | Sort-Object -Unique | ForEach-Object {
                Save-Challenge -Plugin $_ -PluginArgs $PluginArgs
            }
        }

    }
}
