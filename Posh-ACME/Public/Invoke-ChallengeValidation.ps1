function Invoke-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DNSPlugin,
        [Parameter(Position=1)]
        [hashtable]$PluginArgs,
        [int]$DnsSleep=120,
        [int]$ValidationTimeout=60,
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
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
        Write-Warning "The server is already issuing or has issued a certificate for order $($Order.MainDomain)."
        return
    } elseif ($Order.status -eq 'ready') {
        Write-Warning "The order $($Order.MainDomain) has already completed challenge validation and is awaiting finalization."
        return
    }

    # The only order status left is 'pending'. This is supposed to mean
    # that at least one authorization hasn't been validated yet according
    # to https://tools.ietf.org/html/draft-ietf-acme-acme-11#section-7.1.6
    # However because the 'ready' status was added to the spec recently,
    # not all server implementations are using it yet. So we're going to
    # check all of the authorization statuses, but there might still end up
    # being nothing to do.

    $allAuths = $Order | Get-PAAuthorizations
    $toValidate = @()

    # fill out the DNSPlugin attribute so there's a value for each authorization in the order
    if (!$DNSPlugin) {
        Write-Warning "DNSPlugin not specified. Defaulting to Manual."
        $DNSPlugin = @('Manual') * $allAuths.Count
    } elseif ($DNSPlugin.Count -lt $Domain.Count) {
        $lastPlugin = $DNSPlugin[-1]
        Write-Warning "Fewer DNSPlugin values than Domain values supplied. Using $lastPlugin for the rest."
        $DNSPlugin += @($lastPlugin) * ($allAuths.Count-$DNSPlugin.Count)
    }
    Write-Verbose "DNSPlugin: $($DNSPlugin -join ',')"

    try {
        # loop through the authorizations looking for challenges to validate
        for ($i=0; $i -lt ($allAuths.Count); $i++) {
            $auth = $allAuths[$i]

            # skip ones that are already valid
            if ($auth.status -eq 'valid') {
                Write-Host "$($auth.fqdn) authorization is already valid"
                continue

            } elseif ($auth.status -eq 'pending') {

                if ($auth.DNS01Status -eq 'pending') {
                    # publish the necessary TXT record
                    Write-Host "Publishing DNS challenge for $($auth.fqdn)"
                    Publish-DNSChallenge $auth.DNSId $Account $auth.DNS01Token $DNSPlugin[$i] $PluginArgs
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
            $DNSPlugin[$toValidate] | Select-Object -Unique | ForEach-Object {
                Write-Host "Saving changes for $_ plugin"
                Save-DNSChallenge $_ $PluginArgs
            }

            # sleep while the DNS changes propagate
            Write-Host "Sleeping for $DNSSleep seconds while DNS change take effect"
            Start-Sleep -Seconds $DNSSleep

            # ask the server to validate the challenges
            Write-Host "Requesting challenge validations"
            $header = @{ alg=$Account.alg; kid=$Account.location; nonce=''; url='' }
            foreach ($chalUrl in $allAuths[$toValidate].DNS01Url) {
                $header.nonce = $script:Dir.nonce
                $header.url   = $chalUrl
                try { $response = Invoke-ACME $header.url ($Account.key | ConvertFrom-Jwk) $header '{}' -EA Stop } catch {}
                Write-Verbose "$($response.Content)"
            }

            # and wait for them to succeed or fail
            Wait-AuthValidation @($allAuths[$toValidate].location) $ValidationTimeout
        }

    } finally {
        # always cleanup the TXT records if they were added
        for ($i=0; $i -lt $toValidate.Count; $i++) {
            Unpublish-DNSChallenge $allAuths[$i].DNSId $Account $allAuths[$i].DNS01Token $DNSPlugin[$i] $PluginArgs
        }
        $DNSPlugin[$toValidate] | Select-Object -Unique | ForEach-Object {
            Write-Host "Saving changes for $_ plugin"
            Save-DNSChallenge $_ $PluginArgs
        }
    }

}
