function New-PACertificate {
    [CmdletBinding(DefaultParameterSetName='FromScratch')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='FromScratch',Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(ParameterSetName='FromCSR',Mandatory,Position=0)]
        [Alias('CSRString')]
        [string]$CSRPath,
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [string[]]$Contact,
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$CertKeyLength='2048',
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$AlwaysNewKey,
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='ec-256',
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl='LE_PROD',
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [Alias('DnsPlugin')]
        [string[]]$Plugin,
        [hashtable]$PluginArgs,
        [ValidateRange(0, 3650)]
        [int]$LifetimeDays,
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$OCSPMustStaple,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$Subject,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$PfxPass='poshacme',
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-SecureStringNotNullOrEmpty $_ -ThrowOnFail})]
        [securestring]$PfxPassSecure,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$UseModernPfxEncryption,
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-WinOnly -ThrowOnFail})]
        [switch]$Install,
        [switch]$UseSerialValidation,
        [switch]$Force,
        [int]$DnsSleep=120,
        [int]$ValidationTimeout=60,
        [string]$PreferredChain
    )

    # grab the set of parameter keys to make comparisons easier later
    $psbKeys = $PSBoundParameters.Keys

    # Make sure we have a refreshed server. But don't override the current
    # one unless explicitly specified.
    if ('DirectoryUrl' -in $psbKeys -or -not (Get-PAServer -Refresh)) {
        Set-PAServer -DirectoryUrl $DirectoryUrl
    }
    Write-Verbose "Using ACME Server $($script:Dir.location)"

    # Make sure we have an account set. If Contact and/or AccountKeyLength
    # were specified and don't match the current one but do match a different,
    # one, switch to that. If the specified details don't match any existing
    # accounts, create a new one.
    $acct = Get-PAAccount
    $acctListParams = @{
        List = $true
        Status = 'valid'
    }
    if ('Contact' -in $PSBoundParameters.Keys) { $acctListParams.Contact = $Contact }
    if ('AccountKeyLength' -in $PSBoundParameters.Keys) { $acctListParams.KeyLength = $AccountKeyLength }
    $accts = @(Get-PAAccount @acctListParams)
    if (-not $accts -or $accts.Count -eq 0) {
        # no matches for the set of filters, so create new
        Write-Verbose "Creating a new $AccountKeyLength account with contact: $($Contact -join ', ')"
        try { $acct = New-PAAccount @PSBoundParameters -EA Stop }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    } elseif ($accts.Count -gt 0 -and (-not $acct -or $acct.id -notin $accts.id)) {
        # we got matches, but there's no current account or the current one doesn't match
        # so set the first match as current
        $acct = $accts[0]
        Set-PAAccount -ID $acct.id
    }
    Write-Verbose "Using account $($acct.id)"

    # If using a pre-generated CSR, extract the details so we can generate expected parameters
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $csrDetails = Get-CsrDetails $CSRPath

        $Domain = $csrDetails.Domain
        $CertKeyLength = $csrDetails.KeyLength
        $OCSPMustStaple = New-Object Management.Automation.SwitchParameter($csrDetails.OCSPMustStaple)
    }

    # PfxPassSecure takes precedence over PfxPass if both are specified but we
    # need the value in plain text. So we'll just take over the PfxPass variable
    # to use for the rest of the function.
    if ($PfxPassSecure) {
        # throw a warning if they also specified PfxPass
        if ('PfxPass' -in $psbKeys) {
            Write-Warning "PfxPass and PfxPassSecure were both specified. Using value from PfxPassSecure."
        }

        # override the existing PfxPass parameter
        $PfxPass = [pscredential]::new('u',$PfxPassSecure).GetNetworkCredential().Password
        $PSBoundParameters.PfxPass = $PfxPass
    }

    # Generate an appropriate name if one wasn't specified
    if (-not $Name) {
        $Name = $Domain[0].Replace('*','!')
        Write-Verbose "Order name not specified, using '$Name'"
    }

    # Check for an existing order from the MainDomain/Name for this call and
    # create a new one if:
    # - Force was used
    # - it doesn't exist
    # - is invalid or deactivated
    # - is valid and within the renewal window
    # - is pending, but expired
    # - has different KeyLength
    # - has different SANs
    # - has different CSR
    # - has different Lifetime
    $order = Get-PAOrder -Name $Name -Refresh
    $oldOrder = $null
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object
    if ($Force -or -not $order -or
        $order.status -in 'invalid','deactivated' -or
        ($order.status -eq 'valid' -and $order.RenewAfter -and (Get-DateTimeOffsetNow) -ge ([DateTimeOffset]::Parse($order.RenewAfter))) -or
        ($order.status -eq 'pending' -and (Get-DateTimeOffsetNow) -gt ([DateTimeOffset]::Parse($order.expires))) -or
        $CertKeyLength -ne $order.KeyLength -or
        ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') -or
        ($csrDetails -and $csrDetails.Base64Url -ne $order.CSRBase64Url ) -or
        ($LifetimeDays -and $LifetimeDays -ne $order.LifetimeDays) )
    {

        $oldOrder = $order

        # Create a hashtable of order parameters to splat
        if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
            # most values will be pulled from the CSR
            $orderParams = @{
                CSRPath = $CSRPath
                Name = $Name
            }
        }
        else {
            # set the defaults based on what was passed in
            $orderParams = @{
                Domain                 = $Domain
                Name                   = $Name
                KeyLength              = $CertKeyLength
                OCSPMustStaple         = $OCSPMustStaple
                AlwaysNewKey           = $AlwaysNewKey
                Subject                = $Subject
                FriendlyName           = $FriendlyName
                PfxPass                = $PfxPass
                UseModernPfxEncryption = $UseModernPfxEncryption
                Install                = $Install
            }

            # add values from the old order if they exist and weren't overrridden
            # by explicit parameters
            if ($oldOrder) {
                @(  'OCSPMustStaple'
                    'AlwaysNewKey'
                    'Subject'
                    'FriendlyName'
                    'PfxPass'
                    'UseModernPfxEncryption'
                    'Install' ) | ForEach-Object {

                    if ($oldOrder.$_ -and $_ -notin $psbKeys) {
                        $orderParams.$_ = $oldOrder.$_
                    }
                }
                if ($oldOrder.KeyLength -and 'CertKeyLength' -notin $psbKeys) {
                    $orderParams.KeyLength = $oldOrder.KeyLength
                }

                # add the cert we're replacing if it exists
                if ($cert = ($oldOrder | Get-PACertificate)) {
                    $orderParams.ReplacesCert = $cert.ARIId
                }
            }

            # Make sure FriendlyName is non-empty
            if ([String]::IsNullOrWhiteSpace($orderParams.FriendlyName)) {
                $orderParams.FriendlyName = $Domain[0]
            }
        }

        # add common explicit order parameters backed up by old order params
        @(  'Plugin'
            'LifetimeDays'
            'DnsAlias'
            'DnsSleep'
            'ValidationTimeout'
            'PreferredChain'
            'UseSerialValidation' ) | ForEach-Object {

            if ($_ -in $psbKeys) {
                $orderParams.$_ = $PSBoundParameters.$_
            } elseif ($oldOrder -and $oldOrder.$_) {
                $orderParams.$_ = $oldOrder.$_
            }
        }
        if ('PluginArgs' -in $psbKeys) {
            $orderParams.PluginArgs = $PluginArgs
        }

        # create a new order
        Write-Verbose "Creating a new order '$($Name)' for $($Domain -join ', ')"
        Write-Debug "New order params: `n$($orderParams | ConvertTo-Json -Depth 5)"
        $order = New-PAOrder @orderParams -Force

    } else {
        # set the existing order as active and override explicit order properties that
        # don't need to trigger a new order
        Write-Verbose "Using existing order '$($order.Name)' with status $($order.status)"

        $setOrderParams = @{}
        @(  'AlwaysNewKey'
            'Plugin'
            'PluginArgs'
            'DnsAlias'
            'Install'
            'Subject'
            'FriendlyName'
            'PfxPass'
            'UseModernPfxEncryption'
            'Install'
            'DnsSleep'
            'ValidationTimeout'
            'PreferredChain'
            'UseSerialValidation' ) | ForEach-Object {

            if ($_ -in $psbKeys) {
                $setOrderParams.$_ = $PSBoundParameters.$_
            }
        }
        Write-Debug "Set order params: `n$($setOrderParams | ConvertTo-Json -Depth 5)"
        $order | Set-PAOrder @setOrderParams
        $order = Get-PAOrder
    }

    # deal with "pending" orders that may have authorization challenges to prove
    if ($order.status -eq 'pending') {

        Submit-ChallengeValidation

        # refresh the order status
        $order = Get-PAOrder -Refresh
    }

    # if we've reached this point, it should mean the order status is 'ready' and
    # we're ready to finalize the order.
    if ($order.status -eq 'ready') {

        # make the finalize call
        Write-Verbose "Finalizing the order."
        Submit-OrderFinalize

        # refresh the order status
        $order = Get-PAOrder -Refresh
    }

    # The order should now be finalized and the status should be valid. The only
    # thing left to do is download the cert and chain and write the results to
    # disk
    if ($order.status -eq 'valid' -and -not $order.CertExpires) {

        Complete-PAOrder

    } elseif ($order.CertExpires) {
        Write-Warning "This certificate order has already been completed. Use -Force to overwrite the current certificate."
    }
}
