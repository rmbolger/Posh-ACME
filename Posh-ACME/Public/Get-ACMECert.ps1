function Get-ACMECert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [string[]]$Contact,
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirUrl='LE_STAGE',
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='2048',
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DNSPlugin,
        [hashtable]$PluginArgs,
        [int]$DNSSleep=120,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$CertKeyLength='4096'
    )

    # Make sure we have a server set. But don't override the current
    # one unless explicitly specified.
    if (!(Get-PAServer) -or 'DirUrl' -in $PSBoundParameters.Keys) {
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










    return

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

    # create a new order with the associated domains
    try {
        Write-Host "Creating new order with domain(s) $($Domain -join ', ')"
        $order = New-ACMEOrder -Key $acctKey -Domain $Domain
    } catch {
        $acmeErr = $_.Exception.Data
        if ($acmeErr.type -and $acmeErr.type -like '*:accountDoesNotExist') {
            Write-Warning "Server claims existing account not found. Creating a new one and trying again."
            Set-ACMEConfig -AccountUri (Get-ACMEAccount $acctKey $Contact -AcceptTOS)
            $order = New-ACMEOrder -Key $acctKey -Domain $Domain
        } else {
            throw
        }
    }

    # throw if the status is anything but pending
    if ($order.status -ne 'pending') {
        throw "Unexpected status on new order. Expected 'pending', but got '$($order.status)'."
    }
    # throw if the number of authorizations don't match the number of domains
    if ($order.authorizations.Count -ne $Domain.Count) {
        throw "Unexpected authorizations on new order. Expected $($Domain.Count), but got $($order.authorizations.Count)'."
    }

    # Deal with authorizations. There should be exactly as many as the number of domains
    # passed in for the cert.
    $chalToValidate = @()
    for ($i=0; $i -lt $order.authorizations.Count; $i++) {

        # get auth details
        $authUrl = $order.authorizations[$i]
        $auth = Invoke-RestMethod $authUrl -Method Get

        if ($auth.status -eq 'pending') {
            # for the time being, we're only going to deal with 'dns-01' challenges
            $challenge = $auth.challenges | Where-Object { $_.type -eq 'dns-01' } | Select-Object -first 1

            if ($challenge.status -eq 'pending') {
                # publish the necessary record
                $fqdn = $auth.identifier.value
                $keyauth = (Get-KeyAuthorization $acctKey $challenge.token)
                $plugin = $DNSPlugin[$i]
                Write-Host "Publishing DNS challenge for $fqdn"
                Publish-DNSChallenge $fqdn $keyauth $plugin $PluginArgs

                # Save the URL to validate later
                $chalToValidate += $challenge.url
            } else {
                throw "Unexpected challenge status: $($challenge.status)"
            }
        } else {
            throw "Unexpected authorization status: $($auth.status)"
        }
    }

    # Call the Save function for each unique DNS Plugin used
    $DNSPlugin | Select-Object -Unique | ForEach-Object {
        Write-Host "Saving changes for $_ plugin"
        Save-DNSChallenge $_ $PluginArgs
    }

    # sleep while the DNS changes propagate
    Write-Host "Sleeping for $DNSSleep seconds while DNS change take effect"
    Start-Sleep -Seconds $DNSSleep

    # ask the server to validate the challenges
    Write-Host "Validating challenge(s)"
    $chalToValidate | ForEach-Object {
        Invoke-ChallengeValidation $acctKey $_
    }

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

    # cleanup the challenge records
    for ($i=0; $i -lt $order.authorizations.Count; $i++) {
        Unpublish-DNSChallenge $authCache[$i].identifier.value $DNSPlugin[$i] $PluginArgs
    }



}
