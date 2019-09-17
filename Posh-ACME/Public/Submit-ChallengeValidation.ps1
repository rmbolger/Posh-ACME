function Submit-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string[]]$Plugin,
        [Parameter(Position=1)]
        [hashtable]$PluginArgs,
        [string[]]$DnsAlias,
        [int]$DnsSleep=120,
        [int]$ValidationTimeout=60,
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # Here's the overview of this function's purpose:
    # - publish challenges for any pending authorizations in the Order
    # - notify ACME server to validate those challenges
    # - wait until the validations are complete (good or bad)
    # - unpublish the challenges that were published
    # - return the updated order if successful, otherwise throw

    # make sure any account passed in is actually associated with the current server
    # or if no account was specified, that there's a current account.
    if (!$Account) {
        if (!($Account = Get-PAAccount)) {
            throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
        }
    } else {
        if ($Account.id -notin (Get-PAAccount -List).id) {
            throw "Specified account id $($Account.id) was not found in the current server's account list."
        }
    }
    # make sure it's valid
    if ($Account.status -ne 'valid') {
        throw "Account status is $($Account.status)."
    }

    # make sure any order passed in is actually associated with the account
    # or if no order was specified, that there's a current order.
    if (!$Order) {
        if (!($Order = Get-PAOrder)) {
            throw "No Order parameter specified and no current order selected. Try running Set-PAOrder first."
        }
    } else {
        if ($Order.MainDomain -notin (Get-PAOrder -List).MainDomain) {
            throw "Specified order for $($Order.MainDomain) was not found in the current account's order list."
        }
    }

    # make sure the order has a valid state for this function
    if ($Order.status -eq 'invalid') {
        throw "Order status is invalid for $($Order.MainDomain). Unable to continue."

    } elseif ($Order.status -in 'valid','processing') {
        Write-Warning "The server has already issued or is processing a certificate for order $($Order.MainDomain)."
        return

    } elseif ($Order.status -eq 'ready') {
        Write-Warning "The order $($Order.MainDomain) has already completed challenge validation and is awaiting finalization."
        return
    }

    # The only order status left is 'pending'. This means that at least one
    # authorization hasn't been validated yet according to
    # https://tools.ietf.org/html/rfc8555#section-7.1.6
    # So we're going to check all of the authorization statuses and publish
    # records for any that are still pending.

    $allAuths = @($Order | Get-PAAuthorizations)
    $published = @()

    # fill out the Plugin attribute so there's a value for each authorization in the order
    if (!$Plugin) {
        Write-Warning "Plugin not specified. Defaulting to Manual."
        $Plugin = @('Manual') * $allAuths.Count
    } elseif ($Plugin.Count -lt $allAuths.Count) {
        $lastPlugin = $Plugin[-1]
        Write-Warning "Fewer Plugin values than names in the order. Using $lastPlugin for the rest."
        $Plugin += @($lastPlugin) * ($allAuths.Count-$Plugin.Count)
    }
    Write-Debug "Plugin: $($Plugin -join ',')"

    # fill out the DnsAlias attribute so there's a value for each authorization in the order
    if (!$DnsAlias) {
        # no alias means they should all just be empty
        $DnsAlias = @('') * $allAuths.Count
    } elseif ($DnsAlias.Count -lt $allAuths.Count) {
        $lastAlias = $DnsAlias[-1]
        Write-Warning "Fewer DnsAlias values than names in the order. Using $lastAlias for the rest."
        $DnsAlias += @($lastAlias) * ($allAuths.Count-$DnsAlias.Count)
    }
    Write-Debug "DnsAlias: $($DnsAlias -join ',')"

    if ($PluginArgs) {
        # export explicit args to the common account store
        Export-PluginArgs $PluginArgs $Plugin -Account $Account
    }
    # import existing args from the common account store
    $PluginArgs = Import-PluginArgs $Plugin -Account $Account

    try {
        # loop through the authorizations looking for challenges to validate
        for ($i=0; $i -lt $allAuths.Count; $i++) {
            $auth = $allAuths[$i]

            if ($auth.status -eq 'pending') {

                # Determine which challenge to publish based on the plugin type
                $chalType = Get-PluginType $Plugin[$i]
                $challenge = $auth.challenges | Where-Object { $_.type -eq $chalType }
                if (-not $challenge) {
                    throw "$($auth.fqdn) authorization contains no challenges that match the plugin type: $($Plugin[$i]) ($chalType)"
                }

                Publish-Challenge $auth.DNSId $Account $challenge.token $Plugin[$i] $PluginArgs -DnsAlias $DnsAlias[$i]

                # save the details of what we published for cleanup later
                $published += @{
                    identifier = $auth.DNSId
                    fqdn = $auth.fqdn
                    authUrl = $auth.location
                    plugin = $Plugin[$i]
                    chalType = $chalType
                    chalToken = $challenge.token
                    chalUrl = $challenge.url
                    DNSAlias = $DnsAlias[$i]
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

        # if we published any records, now we need to save them, wait for DNS
        # to propagate, and notify the server it can perform the validation
        if ($published.Count -gt 0) {

            # grab the set of unique plugins that were used to publish challenges
            $uniquePluginsUsed = $published.plugin | Sort-Object -Unique

            # call the Save function for each plugin used
            $uniquePluginsUsed | ForEach-Object {
                Write-Verbose "Saving changes for $_ plugin"
                Save-Challenge $_ $PluginArgs
            }

            # sleep while DNS changes propagate if there were DNS challenges published
            if ($DnsSleep -gt 0 -and 'dns-01' -in ($uniquePluginsUsed | Get-PluginType)) {
                Write-Verbose "Sleeping for $DnsSleep seconds while DNS change(s) propagate"
                Start-SleepProgress $DnsSleep -Activity "Waiting for DNS to propagate"
            }

            # ask the server to validate the challenges
            Write-Verbose "Requesting challenge validations"
            $published.chalUrl | Send-ChallengeAck -Account $Account

            # and wait for them to succeed or fail
            Wait-AuthValidation @($published.authUrl) $ValidationTimeout
        }

    } finally {
        # always cleanup the challenges that were published
        $published | ForEach-Object {
            Unpublish-Challenge $_.identifier $Account $_.chalToken $_.plugin $PluginArgs -DnsAlias $_.DNSAlias
        }

        # save the cleanup changes
        $published.plugin | Sort-Object -Unique | ForEach-Object {
            Write-Verbose "Saving changes for $_ plugin"
            Save-Challenge $_ $PluginArgs
        }
    }





    <#
    .SYNOPSIS
        Respond to authorization challenges for an ACME order and wait for the ACME server to validate them.

    .DESCRIPTION
        An ACME order contains an authorization object for each domain in the order. The client must complete at least one of a set of challenges for each authorization in order to prove they own the domain. Once complete, the client asks the server to validate each challenge and waits for the server to do so and update the authorization status.

    .PARAMETER Plugin
        One or more DNS plugin names to use for this order's DNS challenges. If no plugin is specified, the "Manual" plugin will be used. If the same plugin is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the ACME order.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified Plugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

        These arguments are saved to the current ACME account so they can be used automatically for subsequent certificates and renewals. New values will overwrite saved values for existing parameters.

    .PARAMETER DnsAlias
        One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone. This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records. If the same alias is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

    .PARAMETER DnsSleep
        Number of seconds to wait for DNS changes to propagate before asking the ACME server to validate DNS challenges. Default is 120.

    .PARAMETER ValidationTimeout
        Number of seconds to wait for the ACME server to validate the challenges after asking it to do so. Default is 60. If the timeout is exceeded, an error will be thrown.

    .PARAMETER Account
        If specified, switch to and use this account for the validations. It must be associated with the current server or an error will be thrown.

    .PARAMETER Order
        If specified, switch to and use this order for the validations. It must be associated with the current or specified account or an error will be thrown.

    .EXAMPLE
        Submit-ChallengeValidation

        Invoke manual DNS challenge validation on the currently selected account and order.

    .EXAMPLE
        $pluginArgs = @{FBServer='fb.example.com'; FBCred=(Get-Credential)}
        PS C:\>Submit-ChallengeValidation Flurbog $pluginArgs

        Invoke DNS challenge validation using the hypothetical Flurbog plugin on the currently selected account and order.

    .EXAMPLE
        $pluginArgs = @{FBServer='fb.example.com'; FBCred=(Get-Credential)}
        PS C:\>Submit-ChallengeValidation Flurbog $pluginArgs -DnsAlias validate.alt-example.com

        This is the same as the previous example except that it's telling the Flurbog plugin to write to an alias domain. This only works if you have already created a CNAME record for the domain(s) in the order that points to validate.alt-example.com.

    .EXAMPLE
        $order = Get-PAOrder site1.example.com
        PS C:\>Submit-ChallengeValidation -Order $order

        Invoke manual DNS challenge validation on the specified order and currently selected account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
