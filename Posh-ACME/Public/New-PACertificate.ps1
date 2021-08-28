function New-PACertificate {
    [CmdletBinding(DefaultParameterSetName='FromScratch')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='FromScratch',Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(ParameterSetName='FromCSR',Mandatory,Position=0)]
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
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$OCSPMustStaple,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$PfxPass='poshacme',
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-SecureStringNotNullOrEmpty $_ -ThrowOnFail})]
        [securestring]$PfxPassSecure,
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

    # Make sure we have a server set. But don't override the current
    # one unless explicitly specified.
    if (-not (Get-PAServer) -or 'DirectoryUrl' -in $psbKeys) {
        Set-PAServer -DirectoryUrl $DirectoryUrl
    } else {
        # refresh the directory info (which should also get a fresh nonce)
        Set-PAServer
    }
    Write-Verbose "Using ACME Server $($script:Dir.location)"

    # Make sure we have an account set. If Contact and/or AccountKeyLength
    # were specified and don't match the current one but do match a different,
    # one, switch to that. If the specified details don't match any existing
    # accounts, create a new one.
    $acct = Get-PAAccount
    $acctListParams = @{
        List = $true
        Refresh = $true
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
    $order = Get-PAOrder -Name $Name -Refresh
    $oldOrder = $null
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object
    if ($Force -or -not $order -or
        $order.status -in 'invalid','deactivated' -or
        ($order.status -eq 'valid' -and $order.RenewAfter -and (Get-DateTimeOffsetNow) -ge ([DateTimeOffset]::Parse($order.RenewAfter))) -or
        ($order.status -eq 'pending' -and (Get-DateTimeOffsetNow) -gt ([DateTimeOffset]::Parse($order.expires))) -or
        $CertKeyLength -ne $order.KeyLength -or
        ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') -or
        ($csrDetails -and $csrDetails.Base64Url -ne $order.CSRBase64Url ) )
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
                Domain         = $Domain
                Name           = $Name
                KeyLength      = $CertKeyLength
                OCSPMustStaple = $OCSPMustStaple
                AlwaysNewKey   = $AlwaysNewKey
                FriendlyName   = $FriendlyName
                PfxPass        = $PfxPass
                Install        = $Install
            }

            # add values from the old order if they exist and weren't overrridden
            # by explicit parameters
            if ($oldOrder) {
                @(  'OCSPMustStaple'
                    'AlwaysNewKey'
                    'FriendlyName'
                    'PfxPass'
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

        # add common explicit order parameters backed up by old order params
        @(  'Plugin'
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
            'FriendlyName'
            'PfxPass'
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





    <#
    .SYNOPSIS
        Request a new certificate

    .DESCRIPTION
        This is the primary function for this module and is capable executing the entire ACME certificate request process from start to finish without any prerequisite steps. However, utilizing the module's other functions can enable more complicated workflows and reduce the number of parameters you need to supply to this function.

    .PARAMETER Domain
        One or more domain names to include in this order/certificate. The first one in the list will be considered the "MainDomain" and be set as the subject of the finalized certificate.

    .PARAMETER CSRPath
        The path to a pre-made certificate request file in PEM (Base64) format. This is useful for appliances that need to generate their own keys and cert requests.

    .PARAMETER Name
        The name of the ACME order. This can be useful to distinguish between two orders that have the same MainDomain.

    .PARAMETER Contact
        One or more email addresses to associate with this certificate. These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

    .PARAMETER CertKeyLength
        The type and size of private key to use for the certificate. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to '2048'.

    .PARAMETER AlwaysNewKey
        If specified, the order will be configured to always generate a new private key during each renewal. Otherwise, the old key is re-used if it exists.

    .PARAMETER AcceptTOS
        This switch is required when creating a new account as part of a certificate request. It implies you have read and accepted the Terms of Service for the ACME server you are connected to. The first time you connect to an ACME server, a link to the Terms of Service should have been displayed.

    .PARAMETER AccountKeyLength
        The type and size of private key to use for the account associated with this certificate. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to 'ec-256'.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2). Defaults to 'LE_PROD'.

    .PARAMETER Plugin
        One or more validation plugin names to use for this order's challenges. If no plugin is specified, the DNS "Manual" plugin will be used. If the same plugin is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the order.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified Plugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER DnsAlias
        One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone. This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records. If the same alias is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

    .PARAMETER OCSPMustStaple
        If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

    .PARAMETER FriendlyName
        Set a friendly name for the certificate. This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported. Defaults to the first item in the Domain parameter.

    .PARAMETER PfxPass
        Set the export password for generated PFX files. Defaults to 'poshacme'. When the PfxPassSecure parameter is specified, this parameter is ignored.

    .PARAMETER PfxPassSecure
        Set the export password for generated PFX files using a SecureString value. When this parameter is specified, the PfxPass parameter is ignored.

    .PARAMETER Install
        If specified, the certificate generated for this order will be imported to the local computer's Personal certificate store. Using this switch requires running the command from an elevated PowerShell session.

    .PARAMETER UseSerialValidation
        If specified, the names in the order will be validated individually rather than all at once. This can significantly increase the time it takes to process validations and should only be used for plugins that require it. The plugin's usage guide should indicate whether it is required.

    .PARAMETER Force
        If specified, a new certificate order will always be created regardless of the status of a previous order for the same primary domain. Otherwise, the previous order still in progress will be used instead.

    .PARAMETER DnsSleep
        Number of seconds to wait for DNS changes to propagate before asking the ACME server to validate DNS challenges. Default is 120.

    .PARAMETER ValidationTimeout
        Number of seconds to wait for the ACME server to validate the challenges after asking it to do so. Default is 60. If the timeout is exceeded, an error will be thrown.

    .PARAMETER PreferredChain
        If the CA offers multiple certificate chains, prefer the chain with an issuer matching this Subject Common Name. If no match, the default offered chain will be used.

    .EXAMPLE
        New-PACertificate site1.example.com -AcceptTOS

        This is the minimum parameters needed to generate a certificate for the specified site if you haven't already setup an ACME account. It will prompt you to add the required DNS TXT record manually. Once you have an account created, you can omit the -AcceptTOS parameter.

    .EXAMPLE
        New-PACertificate 'site1.example.com','site2.example.com' -Contact admin@example.com

        Request a SAN certificate with multiple names and have notifications sent to the specified email address.

    .EXAMPLE
        New-PACertificate '*.example.com','example.com'

        Request a wildcard certificate that includes the root domain as a SAN.

    .EXAMPLE
        $pluginArgs = @{FBServer='fb.example.com'; FBCred=(Get-Credential)}
        PS C:\>New-PACertificate site1.example.com -Plugin Flurbog -PluginArgs $pluginArgs

        Request a certificate using the hypothetical Flurbog DNS plugin that requires a server name and set of credentials.

    .EXAMPLE
        $pluginArgs = @{FBServer='fb.example.com'; FBCred=(Get-Credential)}
        PS C:\>New-PACertificate site1.example.com -Plugin Flurbog -PluginArgs $pluginArgs -DnsAlias validate.alt-example.com

        This is the same as the previous example except that it's telling the Flurbog plugin to write to an alias domain. This only works if you have already created a CNAME record for _acme-challenge.site1.example.com that points to validate.alt-example.com.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Submit-Renewal

    .LINK
        Get-PAPlugin

    #>
}
