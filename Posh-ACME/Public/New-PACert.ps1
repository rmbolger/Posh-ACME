function New-PACert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [string[]]$Contact,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$CertKeyLength='4096',
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='2048',
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirUrl='LE_STAGE',
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DNSPlugin,
        [hashtable]$PluginArgs,
        [int]$DNSSleep=120,
        [switch]$Force
    )

    # Make sure we have a server set. But don't override the current
    # one unless explicitly specified.
    if (!(Get-PAServer) -or ('DirUrl' -in $PSBoundParameters.Keys)) {
        Set-PAServer $DirUrl
    } else {
        # refresh the directory info (which should also populate $script:NextNonce)
        Update-PAServer
    }
    Write-Host "Using directory $($script:DirUrl)"

    # Make sure we have an account set. But create a new one if Contact
    # and/or AccountKeyLength were specified and don't match the existing one.
    $acct = Set-PAAccount -Search -CreateIfNecessary @PSBoundParameters
    Write-Host "Using account $($acct.id)"

    # Check for an existing order from the MainDomain for this call and create a new
    # one if:
    # - -Force was used
    # - it doesn't exist
    # - is invalid
    # - is valid and within the renewal window
    # - has different KeyLength
    # - has different SANs
    $order = Get-PAOrder $Domain[0] -Refresh
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object
    if ($Force -or !$order -or
        $order.status -eq 'invalid' -or
        ($order.status -eq 'valid' -and (Get-Date) -ge (Get-Date $order.RenewAfter)) -or
        $CertKeyLength -ne $order.KeyLength -or
        ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') ) {
        Write-Host "Creating a new order for $($Domain -join ', ')"
        $order = New-PAOrder $Domain $CertKeyLength -Force
    }
    Write-Host "Using order for $($order.MainDomain) with status $($order.status)"

    # deal with "pending" orders that may have authorization challenges to prove
    if ($order.status -eq 'pending') {

        # For the time being we're only going to support the 'dns-01' challenge because it's the
        # only challenge type supported for wildcard domains and dealing with web servers will be a pain.

        # normalize the DNSPlugin attribute so there's a value for each domain passed in
        if (!$DNSPlugin) {
            Write-Warning "DNSPlugin not specified. Defaulting to Manual."
            $DNSPlugin = @()
            for ($i=0; $i -lt $Domain.Count; $i++) { $DNSPlugin += 'Manual' }
        } elseif ($DNSPlugin.Count -lt $Domain.Count) {
            $lastPlugin = $DNSPlugin[-1]
            Write-Warning "Fewer DNSPlugin values than Domain values supplied. Using $lastPlugin for the rest."
            for ($i=$DNSPlugin.Count; $i -lt $Domain.Count; $i++) { $DNSPlugin += $lastPlugin }
        }

        # loop through the authorizations looking for challenges to validate
        $authIndexesToValidate = @()
        $allAuths = $order | Get-PAAuthorizations
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
                    Publish-DNSChallenge $auth.DNsId $acct $auth.DNS01Token $Plugin[$i] $PluginArgs
                    $authIndexesToValidate += $i
                } else {
                    throw "Unexpected challenge status '$($auth.DNS01Status)' for $($auth.fqdn)."
                }

            } else { #status invalid, revoked, deactivated, or expired
                throw "$($auth.fqdn) authorization status is '$($auth.status)'. Create a new order and try again."
            }
        }

        if ($authIndexesToValidate.Count -gt 0) {

            # Call the Save function for each unique DNS Plugin used
            $DNSPlugin[$authIndexesToValidate] | Select-Object -Unique | ForEach-Object {
                Write-Host "Saving changes for $_ plugin"
                Save-DNSChallenge $_ $PluginArgs
            }

            # sleep while the DNS changes propagate
            Write-Host "Sleeping for $DNSSleep seconds while DNS change take effect"
            Start-Sleep -Seconds $DNSSleep

            # ask the server to validate the challenges
            Write-Host "Validating challenge(s)"
            $allAuths[$authIndexesToValidate] | ForEach-Object {
                Invoke-ChallengeValidation $acct $_.DNS01Url
            }

            # cleanup the TXT records
            for ($i=0; $i -lt $order.authorizations.Count; $i++) {
                Unpublish-DNSChallenge $authCache[$i].identifier.value $DNSPlugin[$i] $PluginArgs
            }

        }

    }



    return


    # wait for authorizations to complete
    $authCache = @($null) * $order.authorizations.count
    for ($tries=1; $tries -le 30; $tries++) {

        # check each authorization for its status
        for ($i=0; $i -lt $order.authorizations.Count; $i++) {

            # skip ones that are already valid
            if ($authCache[$i] -and $authCache[$i].status -eq 'valid') { continue; }

            # grab a fresh copy
            $authCache[$i] = Invoke-RestMethod $order.authorizations[$i] -Method Get -Verbose:$false

            # check for bad news
            if ($authCache[$i].status -eq 'invalid') {
                throw "Authorization for $($authCache[$i].identifier.value) is invalid"
            } else {
                Write-Verbose "Authorization for $($authCache[$i].identifier.value) is $($authCache[$i].status)"
            }
        }

        # finish up if all are valid
        if (0 -eq ($authCache.status | Where-Object { $_ -ne 'valid' }).Count) {
            Write-Host "All authorizations are valid."
            break;
        } else {
            Start-Sleep 2
        }
    }




}
