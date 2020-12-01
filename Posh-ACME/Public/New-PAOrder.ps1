function New-PAOrder {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='FromScratch')]
    [OutputType('PoshACME.PAOrder')]
    param(
        [Parameter(ParameterSetName='FromScratch',Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(ParameterSetName='FromCSR',Mandatory,Position=0)]
        [string]$CSRPath,
        [Parameter(ParameterSetName='FromScratch',Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048',
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string[]]$Plugin,
        [hashtable]$PluginArgs,
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$OCSPMustStaple,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$AlwaysNewKey,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$PfxPass='poshacme',
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-SecureStringNotNullOrEmpty $_ -ThrowOnFail})]
        [securestring]$PfxPassSecure,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$Install,
        [switch]$UseSerialValidation,
        [int]$DnsSleep=120,
        [int]$ValidationTimeout=60,
        [string]$PreferredChain,
        [switch]$Force
    )

    # Make sure we have an account configured
    if (!($acct = Get-PAAccount)) {
        try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # If using a pre-generated CSR, extract the details so we can generate expected parameters
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $CSRPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CSRPath)
        $csrDetails = Get-CsrDetails $CSRPath

        $Domain = $csrDetails.Domain
        $KeyLength = $csrDetails.KeyLength
        $OCSPMustStaple = New-Object Management.Automation.SwitchParameter($csrDetails.OCSPMustStaple)
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
    $order = Get-PAOrder $Domain[0] -Refresh

    # separate the SANs
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] })

    # There's a chance we may be overwriting an existing order here. So check for
    # confirmation if certain conditions are true
    if (!$Force) {

        # skip confirmation if the SANs or KeyLength are different
        # regardless of the original order status
        # or if the order is pending but expired
        if ( ($order -and ($KeyLength -ne $order.KeyLength -or
             (($SANs | Sort-Object) -join ',') -ne (($order.SANs | Sort-Object) -join ',') -or
             ($order.status -eq 'pending' -and (Get-DateTimeOffsetNow) -gt ([DateTimeOffset]::Parse($order.expires))) ))) {
            # do nothing

        # confirm if previous order is still in progress
        } elseif ($order -and $order.status -in 'pending','ready','processing') {

            if (!$PSCmdlet.ShouldContinue("Do you wish to overwrite?",
                "Existing order with status $($order.status).")) { return }

        # confirm if previous order not up for renewal
        } elseif ($order -and $order.status -eq 'valid' -and
                    (Get-DateTimeOffsetNow) -lt ([DateTimeOffset]::Parse($order.RenewAfter))) {

            if (!$PSCmdlet.ShouldContinue("Do you wish to overwrite?",
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
    $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

    # send the request
    try {
        $response = Invoke-ACME $header $payloadJson $acct -EA Stop
    } catch { throw }

    # process the response
    $order = $response.Content | ConvertFrom-Json
    $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

    # fix any dates that may have been parsed by PSCore's JSON serializer
    $order.expires = Repair-ISODate $order.expires

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
        FriendlyName        = $FriendlyName
        PfxPass             = $PfxPass
        Install             = $Install.IsPresent
        UseSerialValidation = $UseSerialValidation.IsPresent
        PreferredChain      = $PreferredChain
        AlwaysNewKey        = $AlwaysNewKey.IsPresent
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

    # add the location from the header
    if ($response.Headers.ContainsKey('Location')) {
        $location = $response.Headers['Location'] | Select-Object -First 1
        Write-Debug "Adding location $location"
        $order | Add-Member -MemberType NoteProperty -Name 'location' -Value $location
    } else {
        try { throw 'No Location header found in newOrder output' }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # save it to memory and disk
    $order.MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force -EA Stop
    $script:Order = $order
    $orderFolder = $order | Get-OrderFolder
    Update-PAOrder -SaveOnly

    # export plugin args now they the order exists on disk
    if ('PluginArgs' -in $PSBoundParameters.Keys) {
        Export-PluginArgs $order.MainDomain $order.Plugin $PluginArgs
    }

    # Make a local copy of the specified CSR file
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $csrDest = Join-Path $orderFolder 'request.csr'
        if ($CSRPath -ne $csrDest) {
            Copy-Item -Path $CSRPath -Destination $csrDest
        }
    }

    # Determine whether to remove the old private key. This is necessary if it exists
    # and we're using a CSR or it's explicitly requested or the new KeyLength doesn't match the old one.
    $keyPath = Join-Path $orderFolder 'cert.key'
    $removeOldKey = ( (Test-Path $keyPath -PathType Leaf) -and
                      ($order.AlwaysNewKey -or $ForceNewKey -or 'FromCSR' -eq $PSCmdlet.ParameterSetName) )

    # backup the old private key if necessary
    if ($removeOldKey) {
        Write-Verbose "Removing old private key"
        $oldKey = Get-ChildItem $keyPath
        $oldKey | Move-Item -Destination { "$($_.FullName).bak" } -Force
    }

    # backup any old certs/requests that might exist
    $oldFiles = Get-ChildItem (Join-Path $orderFolder *) -Include cert.cer,cert.pfx,chain.cer,fullchain.cer,fullchain.pfx
    $oldFiles | Move-Item -Destination { "$($_.FullName).bak" } -Force

    # remove old chain files
    Get-ChildItem (Join-Path $orderFolder 'chain*.cer') -Exclude chain.cer |
        Remove-Item -Force

    return $order




    <#
    .SYNOPSIS
        Create a new order on the current ACME account.

    .DESCRIPTION
        Creating an ACME order is the first step of the certificate request process. To create a SAN certificate with multiple names, include them all in an array for the -Domain parameter. The first name in the list will be considered the "MainDomain" and will also be in the certificate subject field. LetsEncrypt currently limits SAN certificates to 100 names.

        Be aware that only one order per MainDomain per ACME Account can exist with this module. Subsequent orders that have the same MainDomain will overwrite previous orders and certificates under the assumption that you are trying to renew or update the certificate with additional names.

    .PARAMETER Domain
        One or more domain names to include in this order/certificate. The first one in the list will be considered the "MainDomain" and be set as the subject of the finalized certificate.

    .PARAMETER CSRPath
        The path to a pre-made certificate request file in PEM (Base64) format. This is useful for appliances that need to generate their own keys and cert requests.

    .PARAMETER KeyLength
        The type and size of private key to use. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to '2048'.

    .PARAMETER Plugin
        One or more validation plugin names to use for this order's challenges. If no plugin is specified, the DNS "Manual" plugin will be used. If the same plugin is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the order.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified Plugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER DnsAlias
        One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone. This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records. If the same alias is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

    .PARAMETER OCSPMustStaple
        If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

    .PARAMETER AlwaysNewKey
        If specified, the order will be configured to always generate a new private key during each renewal. Otherwise, the old key is re-used if it exists.

    .PARAMETER FriendlyName
        Set a friendly name for the certificate. This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported. Defaults to the first item in the Domain parameter.

    .PARAMETER PfxPass
        Set the export password for generated PFX files. Defaults to 'poshacme'. When the PfxPassSecure parameter is specified, this parameter is ignored.

    .PARAMETER PfxPassSecure
        Set the export password for generated PFX files using a SecureString value. When this parameter is specified, the PfxPass parameter is ignored.

    .PARAMETER Install
        If specified, the certificate generated for this order will be imported to the local computer's Personal certificate store.

    .PARAMETER UseSerialValidation
        If specified, the names in the order will be validated individually rather than all at once. This can significantly increase the time it takes to process validations and should only be used for plugins that require it. The plugin's usage guide should indicate whether it is required.

    .PARAMETER DnsSleep
        Number of seconds to wait for DNS changes to propagate before asking the ACME server to validate DNS challenges.

    .PARAMETER ValidationTimeout
        Number of seconds to wait for the ACME server to validate the challenges after asking it to do so. If the timeout is exceeded, an error will be thrown.

    .PARAMETER PreferredChain
        If the CA offers multiple certificate chains, prefer the chain with an issuer matching this Subject Common Name. If no match, the default offered chain will be used.

    .PARAMETER Force
        If specified, confirmation prompts that may have been generated will be skipped.

    .EXAMPLE
        New-PAOrder site1.example.com

        Create a new order for the specified domain using the default key length.

    .EXAMPLE
        New-PAOrder -Domain 'site1.example.com','site2.example.com','site3.example.com'

        Create a new SAN order for the specified domains using the default key length.

    .EXAMPLE
        New-PAOrder site1.example.com 4096

        Create a new order for the specified domain using an RSA 4096 bit key.

    .EXAMPLE
        New-PAOrder 'site1.example.com','site2.example.com' ec-384 -Force

        Create a new SAN order for the specified domains using an ECC key using P-384 curve that ignores any confirmations.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        Set-PAOrder

    #>
}
