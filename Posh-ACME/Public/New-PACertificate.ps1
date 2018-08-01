function New-PACertificate {
    [CmdletBinding(DefaultParameterSetName='FromScratch')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='FromScratch',Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(ParameterSetName='FromCSR',Mandatory,Position=0)]
        [string]$CSRPath,
        [string[]]$Contact,
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$CertKeyLength='2048',
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$NewCertKey,
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='2048',
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl='LE_PROD',
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DnsPlugin,
        [hashtable]$PluginArgs,
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='FromScratch')]
        [switch]$OCSPMustStaple,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='FromScratch')]
        [string]$PfxPass='poshacme',
        [Parameter(ParameterSetName='FromScratch')]
        [ValidateScript({Test-WinOnly -ThrowOnFail})]
        [switch]$Install,
        [switch]$Force,
        [int]$DNSSleep=120,
        [int]$ValidationTimeout=60,
        [string]$PreferredChain
    )

    # Make sure we have a server set. But don't override the current
    # one unless explicitly specified.
    if (!(Get-PAServer) -or ('DirectoryUrl' -in $PSBoundParameters.Keys)) {
        Set-PAServer $DirectoryUrl
    } else {
        # refresh the directory info (which should also get a fresh nonce)
        Update-PAServer
    }
    Write-Verbose "Using directory $($script:Dir.location)"

    # Make sure we have an account set. If Contact and/or AccountKeyLength
    # were specified and don't match the current one but do match a different,
    # one, switch to that. If the specified details don't match any existing
    # accounts, create a new one.
    $acct = Get-PAAccount
    $accts = @(Get-PAAccount -List -Refresh -Status 'valid' @PSBoundParameters)
    if (!$accts -or $accts.Count -eq 0) {
        # no matches for the set of filters, so create new
        Write-Verbose "Creating a new $AccountKeyLength account with contact: $($Contact -join ', ')"
        $acct = New-PAAccount @PSBoundParameters
    } elseif ($accts.Count -gt 0 -and (!$acct -or $acct.id -notin $accts.id)) {
        # we got matches, but there's no current account or the current one doesn't match
        # so set the first match as current
        $acct = $accts[0]
        Set-PAAccount $acct.id
    }
    Write-Verbose "Using account $($acct.id)"

    # If using a pre-generated CSR, extract the details so we can generate expected parameters
    if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
        $csrDetails = Get-CsrDetails $CSRPath

        $Domain = $csrDetails.Domain
        $CertKeyLength = $csrDetails.KeyLength
        $OCSPMustStaple = New-Object Management.Automation.SwitchParameter($csrDetails.OCSPMustStaple)
    }

    # Check for an existing order from the MainDomain for this call and create a new
    # one if:
    # - -Force was used
    # - it doesn't exist
    # - is invalid or deactivated
    # - is valid and within the renewal window
    # - is pending, but expired
    # - has different KeyLength
    # - has different SANs
    # - has different CSR
    $order = Get-PAOrder $Domain[0] -Refresh
    $oldOrder = $null
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object
    if ($Force -or !$order -or
        $order.status -in 'invalid','deactivated' -or
        ($order.status -eq 'valid' -and $order.RenewAfter -and (Get-DateTimeOffsetNow) -ge ([DateTimeOffset]::Parse($order.RenewAfter))) -or
        ($order.status -eq 'pending' -and (Get-DateTimeOffsetNow) -gt ([DateTimeOffset]::Parse($order.expires))) -or
        $CertKeyLength -ne $order.KeyLength -or
        ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') -or
        ($csrDetails -and $csrDetails.Base64Url -ne $order.CSRBase64Url ) ) {

        if ($order) { $oldOrder = $order }

        # Create a hashtable of order parameters to splat
        if ('FromCSR' -eq $PSCmdlet.ParameterSetName) {
            $orderParams = @{ CSRPath = $CSRPath }

        } else {
            $orderParams = @{
                Domain         = $Domain;
                KeyLength      = $CertKeyLength;
                OCSPMustStaple = $OCSPMustStaple.IsPresent;
                NewKey         = $NewCertKey.IsPresent;
                Install        = $Install.IsPresent;
                FriendlyName   = $FriendlyName;
                PfxPass        = $PfxPass;
            }

            # load values from the old order if they exist and weren't explicitly specified
            if ($order) {
                if ('CertKeyLength' -notin $PSBoundParameters.Keys) {
                    $orderParams.KeyLength = $oldOrder.KeyLength
                }
                if ('OCSPMustStaple' -notin $PSBoundParameters.Keys) {
                    $orderParams.OCSPMustStaple = $oldOrder.OCSPMustStaple
                }
                if ('Install' -notin $PSBoundParameters.Keys -and $oldOrder.Install) {
                    $orderParams.Install = $oldOrder.Install
                }
                if ('FriendlyName' -notin $PSBoundParameters.Keys -and $oldOrder.FriendlyName) {
                    $orderParams.FriendlyName = $oldOrder.FriendlyName
                }
                if ('PfxPass' -notin $PSBoundParameters.Keys -and $oldOrder.PfxPass) {
                    $orderParams.PfxPass = $oldOrder.PfxPass
                }
            }

            # Make sure FriendlyName is non-empty
            if ([String]::IsNullOrWhiteSpace($orderParams.FriendlyName)) {
                $orderParams.FriendlyName = $Domain[0]
            }
        }

        # add new or old preferred chain
        if ('PreferredChain' -in $PSBoundParameters.Keys) {
            $orderParams.PreferredChain = $PreferredChain
        } elseif ($oldOrder.PreferredChain) {
            $orderParams.PreferredChain = $oldOrder.PreferredChain
        }

        # and force a new order
        Write-Verbose "Creating a new order for $($Domain -join ', ')"
        $order = New-PAOrder @orderParams -Force

    } else {
        # set the existing order as current
        Write-Verbose "Using existing order for $($order.MainDomain) with status $($order.status)"
        $order | Set-PAOrder

        # Allow overriding some order properties that don't need to trigger a new order
        if ('Install' -in $PSBoundParameters.Keys -and
            $Install.IsPresent -ne $script:Order.Install)
        {
            Write-Verbose "Overriding Install property with $($Install.IsPresent)"
            $script:Order.Install = $Install.IsPresent
        }
        if ('FriendlyName' -in $PSBoundParameters.Keys -and
            -not [String]::IsNullOrWhiteSpace($FriendlyName) -and
            $FriendlyName -ne $script:Order.FriendlyName)
        {
            Write-Verbose "Overriding FriendlyName property with $FriendlyName"
            $script:Order.FriendlyName = $FriendlyName
        }
        if ('PfxPass' -in $PSBoundParameters.Keys -and
            -not [String]::IsNullOrWhiteSpace($PfxPass) -and
            $PfxPass -ne $script:Order.PfxPass)
        {
            Write-Verbose "Overriding PfxPass property with supplied value"
            $script:Order.PfxPass = $PfxPass
        }
    }

    # add validation parameters to the order object using explicit params
    # backed up by previous order params
    if ('DnsPlugin' -in $PSBoundParameters.Keys) {
        $script:Order.DnsPlugin = $DnsPlugin
    } elseif ($oldOrder) {
        $script:Order.DnsPlugin = $oldOrder.DnsPlugin
    }
    if ('DnsAlias' -in $PSBoundParameters.Keys) {
        $script:Order.DnsAlias = $DnsAlias
    } elseif ($oldOrder) {
        $script:Order.DnsAlias = $oldOrder.DnsAlias
    }
    $script:Order.DnsSleep = $DnsSleep
    if ($oldOrder -and 'DnsSleep' -notin $PSBoundParameters.Keys) {
        $script:Order.DnsSleep = $oldOrder.DnsSleep
    }
    $script:Order.ValidationTimeout = $ValidationTimeout
    if ($oldOrder -and 'ValidationTimeout' -notin $PSBoundParameters.Keys) {
        $script:Order.ValidationTimeout = $oldOrder.ValidationTimeout
    }
    Write-Debug "Saving validation params to order"
    Update-PAOrder -SaveOnly
    $order = $script:Order

    # deal with "pending" orders that may have authorization challenges to prove
    if ($order.status -eq 'pending') {

        # create a hashtable of validation parameters to splat that uses
        # explicit params backed up by previous order params
        $chalParams = @{
            DnsSleep = $order.DnsSleep
            ValidationTimeout = $order.ValidationTimeout
        }
        if ($order.DnsPlugin) {
            $chalParams.DnsPlugin = $order.DnsPlugin
        }
        if ($order.DnsAlias) {
            $chalParams.DnsAlias = $order.DnsAlias
        }
        if ('PluginArgs' -in $PSBoundParameters.Keys) {
            $chalParams.PluginArgs = $PluginArgs
        }

        Submit-ChallengeValidation @chalParams

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
    if ($order.status -eq 'valid' -and !$order.CertExpires) {
        if ([string]::IsNullOrWhiteSpace($order.certificate)) {
            throw "Order status is valid, but no certificate URL was found."
        }

        # Download the cert chain, split it up, and generate a PFX files
        Export-PACertFiles $order

        # check the certificate expiration date so we can update the CertExpires
        # and RenewAfter fields
        Write-Verbose "Updating cert expiration and renewal window"
        $certExpires = (Import-Pem -InputFile (Join-Path $script:OrderFolder 'cert.cer')).NotAfter
        $script:Order.CertExpires = $certExpires.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        $script:Order.RenewAfter = $certExpires.AddDays(-30).ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        Update-PAOrder -SaveOnly

        Write-Verbose "Successfully created certificate."

        $cert = Get-PACertificate

        # install to local computer store if asked
        if ($order.Install) {
            $cert | Install-PACertificate
        }

        # output cert details
        Write-Output $cert

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

    .PARAMETER Contact
        One or more email addresses to associate with this certificate. These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

    .PARAMETER CertKeyLength
        The type and size of private key to use for the certificate. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to '2048'.

    .PARAMETER NewCertKey
        If specified, a new private key will be generated for the certificate. Otherwise, a new key will only be generated if one doesn't already exist for the primary domain or the key type or length have changed from the previous order.

    .PARAMETER AcceptTOS
        This switch is required when creating a new account as part of a certificate request. It implies you have read and accepted the Terms of Service for the ACME server you are connected to. The first time you connect to an ACME server, a link to the Terms of Service should have been displayed.

    .PARAMETER AccountKeyLength
        The type and size of private key to use for the account associated with this certificate. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to '2048'.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2). Defaults to 'LE_PROD'.

    .PARAMETER DnsPlugin
        One or more DNS plugin names to use for this order's DNS challenges. If no plugin is specified, the "Manual" plugin will be used. If the same plugin is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the order.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified DnsPlugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER DnsAlias
        One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone. This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records. If the same alias is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

    .PARAMETER OCSPMustStaple
        If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

    .PARAMETER FriendlyName
        Set a friendly name for the certificate. This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported. Defaults to the first item in the Domain parameter.

    .PARAMETER PfxPass
        Set the export password for generated PFX files. Defaults to 'poshacme'.

    .PARAMETER Install
        If specified, the certificate generated for this order will be imported to the local computer's Personal certificate store. Using this switch requires running the command from an elevated PowerShell session.

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
        PS C:\>New-PACertificate site1.example.com -DnsPlugin Flurbog -PluginArgs $pluginArgs

        Request a certificate using the hypothetical Flurbog DNS plugin that requires a server name and set of credentials.

    .EXAMPLE
        $pluginArgs = @{FBServer='fb.example.com'; FBCred=(Get-Credential)}
        PS C:\>New-PACertificate site1.example.com -DnsPlugin Flurbog -PluginArgs $pluginArgs -DnsAlias validate.alt-example.com

        This is the same as the previous example except that it's telling the Flurbog plugin to write to an alias domain. This only works if you have already created a CNAME record for _acme-challenge.site1.example.com that points to validate.alt-example.com.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Submit-Renewal

    .LINK
        Get-DnsPlugins

    #>
}
