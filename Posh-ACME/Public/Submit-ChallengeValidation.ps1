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
        } elseif ($Order.MainDomain -notin (Get-PAOrder -List).MainDomain) {
            Write-Error "Order for $($Order.MainDomain) was not found in the current account's order list."
            return
        }

        # make sure the order has a valid state for this function
        if ($Order.status -eq 'invalid') {
            Write-Error "Order status is invalid for $($Order.MainDomain). Unable to continue."
            return
        }
        elseif ($Order.status -in 'valid','processing') {
            Write-Warning "The server has already issued or is processing a certificate for order $($Order.MainDomain)."
            return
        }
        elseif ($Order.status -eq 'ready') {
            Write-Warning "The order $($Order.MainDomain) has already completed challenge validation and is awaiting finalization."
            return
        }


        # The only order status left is 'pending'. This means that at least one
        # authorization hasn't been validated yet according to
        # https://tools.ietf.org/html/rfc8555#section-7.1.6
        # So we're going to check all of the authorization statuses and publish
        # records for any that are still pending.

        $allAuths = @($Order | Get-PAAuthorization)
        $published = @()

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
        $PluginArgs = Get-PAPluginArgs $Order.MainDomain

        # loop through the authorizations looking for challenges to validate
        for ($i=0; $i -lt $allAuths.Count; $i++) {

            $auth = $allAuths[$i]
            if ($auth.status -eq 'pending') {

                # Determine which challenge to publish based on the plugin type
                $chalType = $script:Plugins.($Order.Plugin[$i]).ChallengeType
                $challenge = $auth.challenges | Where-Object { $_.type -eq $chalType }
                if (-not $challenge) {
                    throw "$($auth.fqdn) authorization contains no challenges that match $($Order.Plugin[$i]) plugin type, $chalType"
                }

                if ($Order.UseSerialValidation) {
                    # Publish and validate each challenge separately
                    try {
                        Publish-Challenge $auth.DNSId $acct $challenge.token $Order.Plugin[$i] $PluginArgs -DnsAlias $Order.DnsAlias[$i]
                        Save-Challenge $Order.Plugin[$i] $PluginArgs

                        # sleep while DNS changes propagate if it was a DNS challenge that was published
                        if ($Order.DnsSleep -gt 0 -and 'dns-01' -eq $chalType) {
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
                        Unpublish-Challenge $auth.DNSId $acct $challenge.token $Order.Plugin[$i] $PluginArgs -DnsAlias $Order.DnsAlias[$i]
                        Save-Challenge $Order.Plugin[$i] $PluginArgs
                    }
                }
                else {
                    try {
                        # Publish each challenge
                        Publish-Challenge $auth.DNSId $acct $challenge.token $Order.Plugin[$i] $PluginArgs -DnsAlias $Order.DnsAlias[$i]

                        # save the details of what we published for validation and cleanup later
                        $published += @{
                            identifier = $auth.DNSId
                            fqdn = $auth.fqdn
                            authUrl = $auth.location
                            plugin = $Order.Plugin[$i]
                            chalType = $chalType
                            chalToken = $challenge.token
                            chalUrl = $challenge.url
                            DNSAlias = $Order.DnsAlias[$i]
                        }
                    }
                    catch {
                        $PSCmdlet.ThrowTerminatingError($_)
                    }
                }

            } elseif ($auth.status -eq 'valid') {
                # skip ones that are already valid
                Write-Verbose "$($auth.fqdn) authorization is already valid"
                continue
            } else {
                #status invalid, revoked, deactivated, or expired
                throw "$($auth.fqdn) authorization status is '$($auth.status)'. Create a new order and try again."
            }
        }

        if (-not $Order.UseSerialValidation) {
            try {
                # if we published any records, now we need to save them, wait for DNS
                # to propagate, and notify the server it can perform the validation
                if ($published.Count -gt 0) {

                    # grab the set of unique plugins that were used to publish challenges
                    $uniquePluginsUsed = $published.plugin | Sort-Object -Unique

                    # call the Save function for each plugin used
                    $uniquePluginsUsed | ForEach-Object {
                        Save-Challenge $_ $PluginArgs
                    }

                    # sleep while DNS changes propagate if there were DNS challenges published
                    $uniqueChalTypes = $script:Plugins[$uniquePluginsUsed].ChallengeType
                    if ($Order.DnsSleep -gt 0 -and 'dns-01' -in $uniqueChalTypes) {
                        Write-Verbose "Sleeping for $($Order.DnsSleep) seconds while DNS change(s) propagate"
                        Start-SleepProgress $Order.DnsSleep -Activity "Waiting for DNS to propagate"
                    }

                    # ask the server to validate the challenges
                    Write-Verbose "Requesting challenge validations"
                    $published.chalUrl | Send-ChallengeAck -Account $acct

                    # and wait for them to succeed or fail
                    Wait-AuthValidation @($published.authUrl) $Order.ValidationTimeout
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
            finally {
                # always cleanup the challenges that were published
                $published | ForEach-Object {
                    Unpublish-Challenge $_.identifier $acct $_.chalToken $_.plugin $PluginArgs -DnsAlias $_.DNSAlias
                }

                # save the cleanup changes
                $published.plugin | Sort-Object -Unique | ForEach-Object {
                    Save-Challenge $_ $PluginArgs
                }
            }
        }

    }





    <#
    .SYNOPSIS
        Respond to authorization challenges for an ACME order and wait for the ACME server to validate them.

    .DESCRIPTION
        An ACME order contains an authorization object for each domain in the order. The client must complete at least one of a set of challenges for each authorization in order to prove they own the domain. Once complete, the client asks the server to validate each challenge and waits for the server to do so and update the authorization status.

    .PARAMETER Order
        The ACME order to perform the validations against. The order object must be associated with the currently active ACME account.

    .EXAMPLE
        Submit-ChallengeValidation

        Begin challenge validation on the current order.

    .EXAMPLE
        Get-PAOrder 111 | Submit-ChallengeValidation

        Begin challenge validation on the specified order.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
