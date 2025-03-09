function New-PACertificate {
    [CmdletBinding(DefaultParameterSetName='FromScratch')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable','')]
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
        [string]$PreferredChain,
        [string]$Profile
    )

    # grab the set of parameter keys to make comparisons easier later
    $psbKeys = $PSBoundParameters.Keys

    if ('PfxPass' -in $psbKeys) {
        if ($PfxPassSecure) {
            # Warn that PfxPassSecure takes precedence over PfxPass if both are specified.
            Write-Warning "PfxPass and PfxPassSecure were both specified. Using value from PfxPassSecure."
        } else {
            # Convert PfxPass to PfxPassSecure so it doesn't get logged in plain text.
            Write-Debug "Converting PfxPass to PfxPassSecure"
            $PfxPassSecure = ConvertTo-SecureString $PfxPass -AsPlainText -Force
            $PSBoundParameters.PfxPassSecure = $PfxPassSecure
        }
        $null = $PSBoundParameters.Remove('PfxPass')
        $PfxPass = $null
    }

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
        ('CertKeyLength' -in $psbKeys -and $CertKeyLength -ne $order.KeyLength) -or
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
                    'UseModernPfxEncryption'
                    'Install' ) | ForEach-Object {

                    if ($oldOrder.$_ -and $_ -notin $psbKeys) {
                        $orderParams.$_ = $oldOrder.$_
                    }
                }
                if ($oldOrder.KeyLength -and 'CertKeyLength' -notin $psbKeys) {
                    $orderParams.KeyLength = $oldOrder.KeyLength
                }
            }

            # Make sure FriendlyName is non-empty
            if ([String]::IsNullOrWhiteSpace($orderParams.FriendlyName)) {
                $orderParams.FriendlyName = $Domain[0]
            }
        }

        # Add the replaced cert ID if it exists
        # New-PAOrder will ignore it if the server doesn't support ARI
        if ($oldOrder -and ($cert = ($oldOrder | Get-PACertificate))) {
            if ($cert.ARIId) {
                $orderParams.ReplacesCert = $cert.ARIId
            }
        }

        # add common explicit order parameters backed up by old order params
        @(  'Plugin'
            'LifetimeDays'
            'DnsAlias'
            'DnsSleep'
            'ValidationTimeout'
            'PreferredChain'
            'Profile'
            'UseSerialValidation' ) | ForEach-Object {

            if ($_ -in $psbKeys) {
                $orderParams.$_ = $PSBoundParameters.$_
            } elseif ($oldOrder -and $oldOrder.$_) {
                $orderParams.$_ = $oldOrder.$_
            }
        }

        # Add the old PfxPass if it exists and a new one wasn't explicitly specified
        if ($oldOrder -and 'PfxPassSecure' -notin $psbKeys) {
            $orderParams.PfxPassSecure = ConvertTo-SecureString $oldOrder.PfxPass -AsPlainText -Force
        } else {
            # Otherwise use the explicit or default value
            $orderParams.PfxPassSecure = $PfxPassSecure
        }

        # Add new PluginArgs if specified
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
            'PfxPassSecure'
            'UseModernPfxEncryption'
            'Install'
            'DnsSleep'
            'ValidationTimeout'
            'PreferredChain'
            'Profile'
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
