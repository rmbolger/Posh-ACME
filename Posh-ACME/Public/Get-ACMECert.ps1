function Get-ACMECert {
    [CmdletBinding(DefaultParameterSetName='WellKnown')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [string[]]$Contact,
        [switch]$AcceptTOS,
        [Parameter(ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnownACMEServer='LE_STAGE',
        [Parameter(ParameterSetName='Custom')]
        [string]$CustomACMEServer,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='2048',
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DNSPlugin,
        [hashtable]$PluginArgs
    )

    # We want to make sure we have a valid directory specified
    # But we don't want to overwrite a saved one unless they explicitly
    # specified a new one
    if ([string]::IsNullOrWhiteSpace($script:cfg.CurrentDir) -or
        ('WellKnownACMEServer' -in $PSBoundParameters.Keys -or 'CustomACMEServer' -in $PSBoundParameters.Keys)) {

        # determine which ACME server to use
        if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
            $DirUri = $script:WellKnownDirs[$WellKnownACMEServer]
            Set-ACMEConfig -WellKnownACMEServer $WellKnownACMEServer
        } else {
            $DirUri = $CustomACMEServer
            Set-ACMEConfig -CustomACMEServer $CustomACMEServer
        }
    }

    # normalize the DNSPlugin attribute so there's a value for each domain passed in
    Write-Verbose "Checking DNSPlugin"
    if (!$DNSPlugin) {
        Write-Warning "DNSPlugin not specified. Setting to Manual."
        $DNSPlugin = @()
        for ($i=0; $i -lt $Domain.Count; $i++) { $DNSPlugin += 'Manual' }
    } elseif ($DNSPlugin.Count -lt $Domain.Count) {
        $lastPlugin = $DNSPlugin[-1]
        Write-Warning "Fewer DNSPlugin values than Domain values supplied. Using $lastPlugin for the rest."
        for ($i=$DNSPlugin.Count; $i -lt $Domain.Count; $i++) { $DNSPlugin += $lastPlugin }
    }

    # refresh the directory info (which should also populate $script:NextNonce)
    Update-ACMEDirectory $script:cfg.CurrentDir
    $curcfg = $script:cfg.($script:cfg.CurrentDir)

    # import the existing account key or create a new one
    try {
        $acctKey = $curcfg.AccountKey | ConvertFrom-Jwk -EA Stop

        # warn if they specified an AccountKeyLength that we won't be using
        if ($PSBoundParameters.ContainsKey('AccountKeyLength')) {
            Write-Warning 'Existing account key found. Ignoring -AccountKeyLength parameter.'
        }
    } catch {
        # existing key either doesn't exist or is corrupt
        # so we need to generate a new one
        Write-Verbose 'Creating account key.'
        $acctJwk = New-Jwk $AccountKeyLength
        Set-ACMEConfig -AccountKey $acctJwk -EA Stop
        $acctKey = $acctJwk | ConvertFrom-Jwk
    }

    # make sure we have a valid AccountUri
    if ([string]::IsNullOrWhiteSpace($curcfg.AccountUri)) {
        Set-ACMEConfig -AccountUri (Get-ACMEAccount $acctKey $Contact -AcceptTOS)
    }
    Write-Verbose "AccountUri = $($curcfg.AccountUri)"

    # create a new order with the associated domains
    try {
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
    for ($i=0; $i -lt $order.authorizations.Count; $i++) {
        $authUrl = $order.authorizations[$i]
        $auth = Invoke-RestMethod $authUrl -Method Get

        if ($auth.status -eq 'pending') {
            # for the time being, we're only going to deal with 'dns-01' challenges
            $challenge = $auth.challenges | Where-Object { $_.type -eq 'dns-01' } | Select-Object -first 1

            if ($challenge.status -eq 'pending') {
                Write-Verbose ($auth.identifier.value)
                $keyauth = (Get-KeyAuthorization $acctKey $challenge.token)
                $plugin = $DNSPlugin[$i]
                Publish-DNSChallenge $fqdn $keyauth $plugin $PluginArgs
            }


        } else {
            throw "Unexpected authorization status: $($auth.status)"
        }

    }


}
