function New-PACert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [string[]]$Contact,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$CertKeyLength='2048',
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='ec-256',
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl='LE_STAGE',
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DNSPlugin,
        [hashtable]$PluginArgs,
        [int]$DNSSleep=120,
        [switch]$Force
    )

    # Make sure we have a server set. But don't override the current
    # one unless explicitly specified.
    $dir = Get-PAServer
    if (!$dir -or ('DirectoryUrl' -in $PSBoundParameters.Keys)) {
        Set-PAServer $DirectoryUrl
    } else {
        # refresh the directory info (which should also get a fresh nonce)
        Update-PAServer
    }
    Write-Host "Using directory $($dir.location)"

    # Make sure we have an account set. If Contact and/or AccountKeyLength
    # were specified and don't match the current one but do match a different,
    # one, switch to that. If the specified details don't match any existing
    # accounts, create a new one.
    $accts = Get-PAAccount -List -Refresh | Where-Object { $_.status -ne 'deactivated' }
    if ('AccountKeyLength' -in $PSBoundParameters.Keys) {
        $accts = $accts | Where-Object { $_.KeyLength -eq $AccountKeyLength }
    }
    if ('Contact' -in $PSBoundParameters.Keys) {
        $accts = $accts | Where-Object { (Compare-Object $Contact $_.contact) -eq $null }
    }
    if ($accts -and $accts.Count -gt 0) {
        $acct = $accts[0]
        Set-PAAccount $acct.id
    } else {
        $acct = New-PAAccount @PSBoundParameters
    }
    Write-Host "Using account $($acct.id)"

    # Check for an existing order from the MainDomain for this call and create a new
    # one if:
    # - -Force was used
    # - it doesn't exist
    # - is invalid
    # - is valid and within the renewal window
    # - is pending, but expired
    # - has different KeyLength
    # - has different SANs
    $order = Get-PAOrder $Domain[0] -Refresh
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object
    if ($Force -or !$order -or
        $order.status -eq 'invalid' -or
        ($order.status -eq 'valid' -and (Get-Date) -ge (Get-Date $order.RenewAfter)) -or
        ($order.status -eq 'pending' -and (Get-Date) -gt (Get-Date $order.expires)) -or
        $CertKeyLength -ne $order.KeyLength -or
        ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') ) {
        Write-Host "Creating a new order for $($Domain -join ', ')"
        $order = New-PAOrder $Domain $CertKeyLength -Force
    }
    Write-Host "Using order for $($order.MainDomain) with status $($order.status)"

    # deal with "pending" orders that may have authorization challenges to prove
    if ($order.status -eq 'pending') {

        # For the time being we're only going to support the 'dns-01' challenge because it's the
        # only challenge type supported for wildcard domains, dealing with web servers for http-01
        # will be a pain and both versions of the tls-sni challenge have had support dropped.

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
        try {

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
                        Publish-DNSChallenge $auth.DNSId $acct $auth.DNS01Token $DNSPlugin[$i] $PluginArgs
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
                Invoke-ChallengeValidation $acct $allAuths[$authIndexesToValidate].location $allAuths[$authIndexesToValidate].DNS01Url
            }

        } finally {
            # always cleanup the TXT records if they were added
            for ($i=0; $i -lt $authIndexesToValidate.Count; $i++) {
                Unpublish-DNSChallenge $allAuths[$i].DNSId $acct $allAuths[$i].DNS01Token $DNSPlugin[$i] $PluginArgs
            }
            $DNSPlugin[$authIndexesToValidate] | Select-Object -Unique | ForEach-Object {
                Write-Host "Saving changes for $_ plugin"
                Save-DNSChallenge $_ $PluginArgs
            }
        }

    }

    # refresh the order status
    $order = Get-PAOrder $Domain[0] -Refresh

    $order

}
