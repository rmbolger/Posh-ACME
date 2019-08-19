function Submit-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DnsPlugin,
        [Parameter(Position=1)]
        [hashtable]$PluginArgs,
        [string[]]$DnsAlias,
        [int]$DnsSleep=120,
        [int]$ValidationTimeout=60,
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # For the time being we're only going to support the 'dns-01' challenge because it's the
    # only challenge type supported for wildcard domains, dealing with web servers for http-01
    # will be a pain, and both versions of the tls-sni challenge have had support dropped
    # pending a new tls replacement.

    # Here's the overview of this function's purpose:
    # - publish TXT records for any pending challenges in the Order's authorizations list
    # - notify ACME server to validate those records
    # - wait until the validations are complete (good or bad)
    # - remove the TXT records that were published
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

    } elseif ($Order.status -eq 'valid' -or $Order.status -eq 'processing') {
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
    $toValidate = @()

    # fill out the DnsPlugin attribute so there's a value for each authorization in the order
    if (!$DnsPlugin) {
        Write-Warning "DnsPlugin not specified. Defaulting to Manual."
        $DnsPlugin = @('Manual') * $allAuths.Count
    } elseif ($DnsPlugin.Count -lt $allAuths.Count) {
        $lastPlugin = $DnsPlugin[-1]
        Write-Warning "Fewer DnsPlugin values than names in the order. Using $lastPlugin for the rest."
        $DnsPlugin += @($lastPlugin) * ($allAuths.Count-$DnsPlugin.Count)
    }
    Write-Debug "DnsPlugin: $($DnsPlugin -join ',')"

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
        Export-PluginArgs $PluginArgs $DnsPlugin -Account $Account
    }
    # import existing args from the common account store
    $PluginArgs = Import-PluginArgs $DnsPlugin -Account $Account

    try {
        # loop through the authorizations looking for challenges to validate
        for ($i=0; $i -lt ($allAuths.Count); $i++) {
            $auth = $allAuths[$i]

            # skip ones that are already valid
            if ($auth.status -eq 'valid') {
                Write-Verbose "$($auth.fqdn) authorization is already valid"
                continue

            } elseif ($auth.status -eq 'pending') {

                if ($auth.DNS01Status -eq 'pending') {
                    # publish the necessary TXT record
                    Write-Verbose "Publishing DNS challenge for $($auth.fqdn)"
                    if ([string]::IsNullOrWhiteSpace($DnsAlias[$i])) {
                        # publish normally
                        Publish-DnsChallenge $auth.DNSId $Account $auth.DNS01Token $DnsPlugin[$i] $PluginArgs
                    } else {
                        # publish to alias
                        Publish-DnsChallenge $DnsAlias[$i] $Account $auth.DNS01Token $DnsPlugin[$i] $PluginArgs -NoPrefix
                    }
                    $toValidate += $i
                } else {
                    throw "Unexpected challenge status '$($auth.DNS01Status)' for $($auth.fqdn)."
                }

            } else { #status invalid, revoked, deactivated, or expired
                throw "$($auth.fqdn) authorization status is '$($auth.status)'. Create a new order and try again."
            }
        }

        # if we published any records, now we need to save them, wait for DNS
        # to propagate, and notify the server it can perform the validation
        if ($toValidate.Count -gt 0) {

            # Call the Save function for each unique DNS Plugin used
            $DnsPlugin[$toValidate] | Select-Object -Unique | ForEach-Object {
                Write-Verbose "Saving changes for $_ plugin"
                Save-DnsChallenge $_ $PluginArgs
            }

            if ($DnsSleep -gt 0) {
                # sleep while the DNS changes propagate
                Write-Verbose "Sleeping for $DnsSleep seconds while DNS change(s) propagate"
                Start-SleepProgress $DnsSleep -Activity "Waiting for DNS to propagate"
            }

            # ask the server to validate the challenges
            Write-Verbose "Requesting challenge validations"
            $allAuths[$toValidate].DNS01Url | Send-ChallengeAck -Account $Account

            # and wait for them to succeed or fail
            Wait-AuthValidation @($allAuths[$toValidate].location) $ValidationTimeout
        }

    } finally {
        # always cleanup the TXT records if they were added
        for ($i=0; $i -lt $toValidate.Count; $i++) {
            $index = $toValidate[$i]

            if ([string]::IsNullOrWhiteSpace($DnsAlias[$index])) {
                # unpublish normally
                Unpublish-DnsChallenge $allAuths[$index].DNSId $Account $allAuths[$index].DNS01Token $DnsPlugin[$index] $PluginArgs
            } else {
                # unpublish from alias
                Unpublish-DnsChallenge $DnsAlias[$index] $Account $allAuths[$index].DNS01Token $DnsPlugin[$index] $PluginArgs -NoPrefix
            }
        }
        $DnsPlugin[$toValidate] | Select-Object -Unique | ForEach-Object {
            Write-Verbose "Saving changes for $_ plugin"
            Save-DnsChallenge $_ $PluginArgs
        }
    }





    <#
    .SYNOPSIS
        Respond to authorization challenges for an ACME order and wait for the ACME server to validate them.

    .DESCRIPTION
        An ACME order contains an authorization object for each domain in the order. The client must complete at least one of a set of challenges for each authorization in order to prove they own the domain. Once complete, the client asks the server to validate each challenge and waits for the server to do so and update the authorization status.

    .PARAMETER DnsPlugin
        One or more DNS plugin names to use for this order's DNS challenges. If no plugin is specified, the "Manual" plugin will be used. If the same plugin is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the ACME order.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified DnsPlugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

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
