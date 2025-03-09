function New-PAOrder {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='FromScratch')]
    [OutputType('PoshACME.PAOrder')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable','')]
    param(
        [Parameter(ParameterSetName='FromScratch',Mandatory,Position=0)]
        [Parameter(ParameterSetName='ImportKey',Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(ParameterSetName='FromCSR',Mandatory,Position=0)]
        [Alias('CSRString')]
        [string]$CSRPath,
        [Parameter(ParameterSetName='FromScratch',Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048',
        [Parameter(ParameterSetName='ImportKey',Mandatory)]
        [string]$KeyFile,
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string[]]$Plugin,
        [hashtable]$PluginArgs,
        [ValidateRange(0, 3650)]
        [int]$LifetimeDays,
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [switch]$OCSPMustStaple,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [switch]$AlwaysNewKey,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [string]$Subject,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [string]$PfxPass='poshacme',
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [ValidateScript({Test-SecureStringNotNullOrEmpty $_ -ThrowOnFail})]
        [securestring]$PfxPassSecure,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [switch]$UseModernPfxEncryption,
        [Parameter(ParameterSetName='FromScratch')]
        [Parameter(ParameterSetName='ImportKey')]
        [switch]$Install,
        [switch]$UseSerialValidation,
        [int]$DnsSleep=120,
        [int]$ValidationTimeout=60,
        [string]$PreferredChain,
        [switch]$Force,
        [string]$ReplacesCert,
        [string]$Profile
    )

    try {
        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }
    catch { $PSCmdlet.ThrowTerminatingError($_) }

    # If using a pre-generated CSR, extract the details so we can generate expected parameters
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $csrDetails = Get-CsrDetails $CSRPath

        $Domain = $csrDetails.Domain
        $KeyLength = $csrDetails.KeyLength
        $OCSPMustStaple = New-Object Management.Automation.SwitchParameter($csrDetails.OCSPMustStaple)
    }

    # De-dupe the domain list if necessary
    $domainCount = $Domain.Count
    $Domain = $Domain | Select-Object -Unique
    if ($domainCount -gt $Domain.Count) {
        Write-Warning "One or more duplicate domain values found. Removing duplicates."
    }

    # If importing a key, make sure it's valid so we can set the appropriate KeyLength
    if ('ImportKey' -eq $PSCmdlet.ParameterSetName) {
        $KeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyFile)
        try {
            $kLength = [string]::Empty
            # we don't actually care about the key object, just the parsed length
            $null = New-PAKey -KeyFile $KeyFile -ParsedLength ([ref]$kLength)
            $KeyLength = $kLength
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # PfxPassSecure takes precedence over PfxPass if both are specified but we
    # need the value in plain text. So we'll just take over the PfxPass variable
    # to use for the rest of the function.
    if ($PfxPassSecure) {
        # throw a warning if they also specified PfxPass
        if ('PfxPass' -in $PSBoundParameters.Keys) {
            Write-Warning "PfxPass and PfxPassSecure were both specified. Using value from PfxPassSecure."
        }

        # override the existing PfxPass parameter
        $PfxPass = [pscredential]::new('u',$PfxPassSecure).GetNetworkCredential().Password
        $PSBoundParameters.PfxPass = $PfxPass
    }

    # check for an existing order
    if ($Name) {
        $order = Get-PAOrder -Name $Name
    } else {
        $order = Get-PAOrder -MainDomain $Domain[0]

        # set the default Name to a filesystem friendly version of the first domain
        $Name = $Domain[0].Replace('*','!')
    }

    # separate the SANs
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] })

    # There's a chance we may be overwriting an existing order here. So check for
    # confirmation if certain conditions are true
    if (-not $Force) {

        $oldDomains = (@($order.MainDomain) + @($order.SANs) | Sort-Object) -join ','

        # skip confirmation if the Domains, KeyLength, or Profile are different
        # regardless of the original order status or if the order is pending but expired
        if ( ($order -and ($KeyLength -ne $order.KeyLength -or
             ($oldDomains -ne ($Domain | Sort-Object) -join ',') -or
             ($Profile -and $Profile -ne $order.Profile) -or
             ($order.status -eq 'pending' -and (Get-DateTimeOffsetNow) -gt ([DateTimeOffset]::Parse($order.expires))) ))) {
            # do nothing

        # confirm if previous order is still in progress
        } elseif ($order -and $order.status -in 'pending','ready','processing') {

            if (-not $PSCmdlet.ShouldContinue("Do you wish to overwrite?",
                "Existing order with status $($order.status).")) { return }

        # confirm if previous order not up for renewal
        } elseif ($order -and $order.status -eq 'valid' -and
                    (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($order.RenewAfter))) {

            if (-not $PSCmdlet.ShouldContinue("Do you wish to overwrite?",
                "Existing order has not reached suggested renewal window.")) { return }
        }
    }

    Write-Debug "Creating new $KeyLength order with domains: $($Domain -join ', ')"

    # Force a key change if the KeyLength is different than the old order
    if ($order -and $order.KeyLength -ne $KeyLength) {
        $ForceNewKey = $true
    }

    # build the protected header for the request
    $header = @{
        alg   = $acct.alg;
        kid   = $acct.location;
        nonce = $script:Dir.nonce;
        url   = $script:Dir.newOrder;
    }

    # super lazy IPv4 address regex, but we just need to be able to
    # distinguish from an FQDN
    $reIPv4 = [regex]'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'

    # build the payload object
    $payload = @{identifiers=@()}
    foreach ($d in $Domain) {

        # IP identifiers (RFC8738) are an extension to the original ACME protocol
        # https://tools.ietf.org/html/rfc8738
        #
        # So we have to distinguish between domain FQDNs and IPv4/v6 addresses
        # and send the appropriate identifier type for each one. We don't care
        # if the IP address entered is actually valid or not, only that it is
        # parsable as an IP address and should be sent as one rather than a
        # DNS name.

        if ($d -match $reIPv4 -or $d -like '*:*') {
            Write-Debug "$d identified as IP address. Attempting to parse."
            $ip = [ipaddress]$d

            $payload.identifiers += @{type='ip';value=$ip.ToString()}
        }
        else {
            $payload.identifiers += @{type='dns';value=$d}
        }

    }

    # add the requested certificate lifetime if specified
    if ($LifetimeDays) {
        $now = [DateTimeOffset]::UtcNow
        $notBefore = $now.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        $notAfter = $now.AddDays($LifetimeDays).ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        $payload.notBefore = $notBefore
        $payload.notAfter = $notAfter
    }

    # Add the ARI replaces field if supported and specified
    # https://www.ietf.org/archive/id/draft-ietf-acme-ari-03.html#name-extensions-to-the-order-obj
    if ($ReplacesCert -and -not (Get-PAServer).DisableARI -and (Get-PAServer).renewalInfo) {
        $payload.replaces = $ReplacesCert
    }

    # Add the cert profile if specified
    # https://www.ietf.org/archive/id/draft-aaron-acme-profiles-00.html
    if ($Profile) {
        if ($Profile -in (Get-PAProfile).Profile) {
            $payload.profile = $Profile
        } else {
            Write-Warning "Profile '$Profile' is not currently supported on this ACME server. Ignoring profile selection."
        }
    }

    $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

    # send the request
    try {
        $response = Invoke-ACME $header $payloadJson $acct -EA Stop
    } catch {
        # ACME server should send HTTP 409 Conflict status if we tried to specify
        # a 'replaces' value that has already been replaced. So if we get that,
        # retry the request without that field included.
        # It will also send HTTP 404 for various other reasons that it can't find
        # the cert to be replaced.
        if ($_.Exception.Data.status -in 404,409) {
            Write-Warning $_.Exception.Data.detail
            Write-Verbose "Resubmitting new order without 'replaces' field."
            $payload.Remove('replaces')
            $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress
            try {
                $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            } catch { throw }
        } else {
            throw
        }
    }

    # process the response
    $order = $response.Content | ConvertFrom-Json
    $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

    # fix any dates that may have been parsed by PSCore's JSON serializer
    $order.expires = Repair-ISODate $order.expires

    # add the location from the header
    if ($response.Headers.ContainsKey('Location')) {
        $location = $response.Headers['Location'] | Select-Object -First 1
        Write-Debug "Adding location $location"
        $order | Add-Member -MemberType NoteProperty -Name 'location' -Value $location
    } else {
        try { throw 'No Location header found in newOrder output' }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # Make sure the returned order isn't a duplicate of one we already have a copy
    # of locally. This can happen with Let's Encrypt when an existing order with the
    # same identifiers is still in the 'pending' or 'ready' state.
    $orderConflict = Get-PAOrder -List | Where-Object { $_.location -eq $location -and $_.Name -ne $Name }
    if ($orderConflict) {
        try { throw "ACME Server returned duplicate order details that match existing local order '$($orderConflict.Name)'" }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # Per https://tools.ietf.org/html/rfc8555#section-7.1.3
    # In the returned order object, there is no guarantee that the list of identifiers
    # match the sequence they were submitted in. The list of authorizations may not match
    # either. And the identifiers and authorizations may not even match each other's
    # sequence.
    #
    # Unfortunately, things like DNS plugins and challenge aliases currently depend on
    # the assumption that the sequence of identifiers and the sequence of authorizations
    # all match the original sequence of the submitted domains. So we need to make sure
    # that it's true until we refactor things so those assumptions aren't necessary anymore.

    # set the order's identifiers to the original payload's identifiers since that was
    # correct already
    $order.identifiers = $payload.identifiers

    # unfortunately, there's no way to know which authorization URL is for which identifier
    # just by parsing it. So we need to query the details for each one in order to put them
    # in the right order
    $auths = Get-PAAuthorization $order.authorizations
    for ($i=0; $i -lt $order.identifiers.Count; $i++) {
        $auth = $auths | Where-Object { $_.fqdn -eq $order.identifiers[$i].value }
        $order.authorizations[$i] = $auth.location
    }

    # make sure FriendlyName is non-empty
    if ([String]::IsNullOrWhiteSpace($FriendlyName)) {
        $FriendlyName = $Domain[0]
    }

    # add additional members we'll need for later
    $order | Add-Member -NotePropertyMembers @{
        MainDomain          = $Domain[0]
        SANs                = $SANs
        KeyLength           = $KeyLength
        CertExpires         = $null
        RenewAfter          = $null
        OCSPMustStaple      = $OCSPMustStaple.IsPresent
        Plugin              = @('Manual')
        DnsAlias            = $null
        DnsSleep            = $DnsSleep
        ValidationTimeout   = $ValidationTimeout
        Subject             = $Subject
        FriendlyName        = $FriendlyName
        PfxPass             = $PfxPass
        Install             = $Install.IsPresent
        UseSerialValidation = $UseSerialValidation.IsPresent
        PreferredChain      = $PreferredChain
        AlwaysNewKey        = $AlwaysNewKey.IsPresent
        LifetimeDays        = $null
    }

    # override AlwaysNewKey if they're importing the private key
    if ($order.AlwaysNewKey -and 'ImportKey' -eq $PSCmdlet.ParameterSetName) {
        Write-Warning "AlwaysNewKey was disabled because private key was imported using the KeyFile parameter."
        $order.AlwaysNewKey = $false
    }

    # make sure there's a certificate field for later
    if ('certificate' -notin $order.PSObject.Properties.Name) {
        $order | Add-Member 'certificate' $null
    }

    # add the CSR data if we have it
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $order | Add-Member 'CSRBase64Url' $csrDetails.Base64Url
    }

    # update other optional fields
    if ('Plugin' -in $PSBoundParameters.Keys) {
        $order.Plugin = @($Plugin)
    }
    if ('DnsAlias' -in $PSBoundParameters.Keys) {
        $order.DnsAlias = @($DnsAlias)
    }
    if ('LifetimeDays' -in $PSBoundParameters.Keys) {
        $order.LifetimeDays = $LifetimeDays
    }
    if ('UseModernPfxEncryption' -in $PSBoundParameters.Keys) {
        $order | Add-Member UseModernPfxEncryption $UseModernPfxEncryption.IsPresent -Force
    }

    # add the Name and Folder properties
    $order | Add-Member 'Name' $Name -Force
    $order | Add-Member 'Folder' (Join-Path $acct.Folder $Name) -Force

    # save it to memory and disk
    $order.Name | Out-File (Join-Path $acct.Folder 'current-order.txt') -Force -EA Stop
    $script:Order = $order
    Update-PAOrder $order -SaveOnly

    # export plugin args now that the order exists on disk
    if ('PluginArgs' -in $PSBoundParameters.Keys) {
        Export-PluginArgs -Order $order -PluginArgs $PluginArgs
    }

    # Make a local copy of the specified CSR
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $csrDest = Join-Path $order.Folder 'request.csr'
        Export-Pem $csrDetails.PemLines $csrDest
    }

    # Determine whether to remove the old private key. This is necessary if it exists
    # and we're using a CSR or it's explicitly requested or the new KeyLength doesn't match the old one.
    $keyPath = Join-Path $order.Folder 'cert.key'
    $removeOldKey = ( (Test-Path $keyPath -PathType Leaf) -and
                      ($order.AlwaysNewKey -or $ForceNewKey -or 'FromCSR' -eq $PSCmdlet.ParameterSetName) )

    # backup the old private key if necessary
    if ($removeOldKey) {
        Write-Verbose "Removing old private key"
        $oldKey = Get-ChildItem $keyPath
        $oldKey | Move-Item -Destination { "$($_.FullName).bak" } -Force
    }

    # backup any old certs/requests that might exist
    $oldFiles = Get-ChildItem (Join-Path $order.Folder *) -Include cert.cer,cert.pfx,chain.cer,fullchain.cer,fullchain.pfx
    $oldFiles | Move-Item -Destination { "$($_.FullName).bak" } -Force

    # remove old chain files
    Get-ChildItem (Join-Path $order.Folder 'chain*.cer') -Exclude chain.cer |
        Remove-Item -Force

    # Make a local copy of the private key if it was specified.
    if ('ImportKey' -eq $PSCmdlet.ParameterSetName) {
        if ($keyPath -ne $KeyFile) {
            Copy-Item -Path $KeyFile -Destination $keyPath
        }
    }

    return $order
}
