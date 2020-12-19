function Set-PAOrder {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Edit')]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='Revoke', Mandatory)]
        [switch]$RevokeCert,
        [Parameter(ParameterSetName='Revoke')]
        [switch]$Force,
        [Parameter(ParameterSetName='Edit')]
        [Parameter(ParameterSetName='Revoke')]
        [switch]$NoSwitch,
        [Parameter(ParameterSetName='Edit')]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [Alias('DnsPlugin')]
        [string[]]$Plugin,
        [Parameter(ParameterSetName='Edit')]
        [hashtable]$PluginArgs,
        [Parameter(ParameterSetName='Edit')]
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='Edit')]
        [ValidateNotNullOrEmpty()]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='Edit')]
        [ValidateNotNullOrEmpty()]
        [string]$PfxPass,
        [Parameter(ParameterSetName='Edit')]
        [ValidateScript({Test-SecureStringNotNullOrEmpty $_ -ThrowOnFail})]
        [securestring]$PfxPassSecure,
        [Parameter(ParameterSetName='Edit')]
        [switch]$Install,
        [Parameter(ParameterSetName='Edit')]
        [switch]$OCSPMustStaple,
        [Parameter(ParameterSetName='Edit')]
        [int]$DnsSleep,
        [Parameter(ParameterSetName='Edit')]
        [int]$ValidationTimeout,
        [Parameter(ParameterSetName='Edit')]
        [string]$PreferredChain,
        [Parameter(ParameterSetName='Edit')]
        [switch]$AlwaysNewKey,
        [Parameter(ParameterSetName='Edit')]
        [switch]$UseSerialValidation
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
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
    }

    Process {

        # throw an error if there's no current order and no MainDomain
        # passed in
        if (!$script:Order -and !$MainDomain) {
            try { throw "No ACME order configured. Run New-PAOrder or specify a MainDomain." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # There are 3 types of calls the user might be making here.
        # - order switch
        # - order switch and edit/revoke
        # - edit/revoke only (possibly bulk via pipeline)
        # The default is to switch orders. So we have a -NoSwitch parameter to
        # indicate a non-switching revocation. But there's a chance they could forget
        # to use it for a bulk update. For now, we'll just let it happen and switch
        # to whatever order came through the pipeline last.

        if ($NoSwitch -and $MainDomain) {
            # This is an explicit non-switching edit, so grab a cached reference
            # to the specified order
            $order = Get-PAOrder $MainDomain

            if ($null -eq $order) {
                Write-Warning "Specified order for $MainDomain was not found. No changes made."
                return
            }

        } elseif (!$script:Order -or ($MainDomain -and ($MainDomain -ne $script:Order.MainDomain))) {
            # This is a definite order switch

            # refresh the cached copy
            try {
                Update-PAOrder $MainDomain
            } catch [AcmeException] {
                Write-Warning "Error refreshing order status from ACME server: $($_.Exception.Data.detail)"
            }

            Write-Debug "Switching to order $MainDomain"

            # save it as current
            $MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force -EA Stop

            # reload the cache from disk
            Import-PAConfig -Level 'Order'

            # grab a local reference to the newly current order
            $order = $script:Order

        } else {
            # This is a defacto non-switching edit because they didn't
            # specify a MainDomain. So just use the current order.
            $order = $script:Order
        }

        # Edit or Revoke?
        if ('Edit' -eq $PSCmdlet.ParameterSetName) {

            $saveChanges = $false
            $rewritePfx = $false
            $rewriteCer = $false
            $psbKeys = $PSBoundParameters.Keys

            if ('Plugin' -in $psbKeys -and
                ($null -eq $order.Plugin -or $null -ne (Compare-Object $Plugin $order.Plugin))) {
                Write-Verbose "Setting Plugin to $(($Plugin -join ','))"
                $order.Plugin = $Plugin
                $saveChanges = $true
            }

            if ('PluginArgs' -in $psbKeys) {
                Write-Verbose "Updating plugin args for plugin(s) $(($order.Plugin -join ','))"
                Export-PluginArgs $order.MainDomain $order.Plugin $PluginArgs
            }

            if ('DnsAlias' -in $psbKeys) {
                Write-Verbose "Setting DnsAlias to $($DnsAlias -join ',')"
                $order.DnsAlias = @($DnsAlias)
                $saveChanges = $true
            }

            if ('FriendlyName' -in $psbKeys -and $FriendlyName -ne $order.FriendlyName) {
                Write-Verbose "Setting FriendlyName to '$FriendlyName'"
                $order.FriendlyName = $FriendlyName
                $saveChanges = $true
                $rewritePfx = $true
            }

            if ('PfxPass' -in $psbKeys -and $PfxPass -ne $order.PfxPass) {
                Write-Verbose "Setting PfxPass to '$PfxPass'"
                $order.PfxPass = $PfxPass
                $saveChanges = $true
                $rewritePfx = $true
            }

            if ('Install' -in $psbKeys -and $Install.IsPresent -ne $order.Install) {
                Write-Verbose "Setting Install to $($Install.IsPresent)"
                $order.Install = $Install.IsPresent
                $saveChanges = $true
            }

            if ('OCSPMustStaple' -in $psbKeys -and $OCSPMustStaple.IsPresent -ne $order.OCSPMustStaple) {
                Write-Verbose "Setting OCSPMustStaple to $($OCSPMustStaple.IsPresent)"
                Write-Warning "Changing the value of OCSPMustStaple only affects future certificates generated with this order. It can not change the state of an existing certificate."
                $order.OCSPMustStaple = $OCSPMustStaple.IsPresent
                $saveChanges = $true
            }

            if ('DnsSleep' -in $psbKeys -and $DnsSleep -ne $order.DnsSleep) {
                Write-Verbose "Setting DnsSleep to $DnsSleep"
                $order.DnsSleep = $DnsSleep
                $saveChanges = $true
            }

            if ('ValidationTimeout' -in $psbKeys -and $ValidationTimeout -ne $order.ValidationTimeout) {
                Write-Verbose "Setting ValidationTimeout to $ValidationTimeout"
                $order.ValidationTimeout = $ValidationTimeout
                $saveChanges = $true
            }

            if ('PreferredChain' -in $psbKeys -and $PreferredChain -ne $order.PreferredChain) {
                Write-Verbose "Setting PreferredChain to $PreferredChain"
                $order | Add-Member 'PreferredChain' $PreferredChain -Force
                $saveChanges = $true
                $rewritePfx = $true
                $rewriteCer = $true
            }

            if ('AlwaysNewKey' -in $psbKeys -and
                (-not $order.AlwaysNewKey -or $AlwaysNewKey.IsPresent -ne $order.AlwaysNewKey)
            ) {
                Write-Verbose "Setting AlwaysNewKey to $($AlwaysNewKey.IsPresent)"
                $order | Add-Member 'AlwaysNewKey' $AlwaysNewKey.IsPresent -Force
                $saveChanges = $true
            }

            if ('UseSerialValidation' -in $psbKeys -and
                (-not $order.UseSerialValidation -or $UseSerialValidation.IsPresent -ne $order.UseSerialValidation)
            ) {
                Write-Verbose "Setting UseSerialValidation to $($UseSerialValidation.IsPresent)"
                $order | Add-Member 'UseSerialValidation' $UseSerialValidation.IsPresent -Force
                $saveChanges = $true
            }

            if ($saveChanges) {
                Write-Verbose "Saving order changes"
                $order | Update-PAOrder -SaveOnly
            }

            # re-export certs if necessary
            if ($rewriteCer -or $rewritePfx) {
                $cert = Get-PACertificate $order.MainDomain
                if ($rewriteCer -and $cert) {
                    Export-PACertFiles $order
                } elseif ($rewritePfx -and $cert) {
                    Export-PACertFiles $order -PfxOnly
                }
            }

        } else {
            # RevokeCert was specified

            # make sure the order has a cert to revoke and that it's not already expired
            if (-not $order.CertExpires) {
                Write-Warning "Unable to revoke certificate for $($order.MainDomain). No cert found to revoke."
                return
            }
            if ((Get-DateTimeOffsetNow) -ge ([DateTimeOffset]::Parse($order.CertExpires))) {
                Write-Warning "Unable to revoke certificate for $($order.MainDomain). Cert already expired."
                return
            }

            # make sure the cert file actually exists
            $certFile = Join-Path ($order | Get-OrderFolder) 'cert.cer'
            if (!(Test-Path $certFile -PathType Leaf)) {
                Write-Warning "Unable to revoke certificate. $certFile not found."
                return
            }

            # confirm revocation unless -Force was used
            if (!$Force) {
                if (!$PSCmdlet.ShouldContinue("Are you sure you wish to revoke $($order.MainDomain)?",
                "Revoking a certificate is irreversible and will immediately break any services using it.")) {
                    Write-Verbose "Revocation aborted for $($order.MainDomain)."
                    return
                }
            }

            Write-Verbose "Revoking certificate $($order.MainDomain)."

            # grab the cert file contents, strip the headers, and join the lines
            $certStart = -1; $certEnd = -1;
            $certLines = Get-Content $certFile
            for ($i=0; $i -lt $certLines.Count; $i++) {
                if ($certLines[$i] -eq '-----BEGIN CERTIFICATE-----') {
                    $certStart = $i + 1
                } elseif ($certLines[$i] -eq '-----END CERTIFICATE-----') {
                    $certEnd = $i - 1
                    break
                }
            }
            if ($certStart -lt 0 -or $certEnd -lt 0) {
                try { throw "Malformed certificate file. $certFile" }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
            $certStr = $certLines[$certStart..$certEnd] -join '' | ConvertTo-Base64Url -FromBase64

            # build the header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:Dir.nonce;
                url   = $script:Dir.revokeCert;
            }

            $payloadJson = "{`"certificate`":`"$certStr`"}"

            # send the request
            try {
                Invoke-ACME $header $payloadJson $acct -EA Stop | Out-Null
            } catch { throw }

            # refresh the order
            Update-PAOrder $order.MainDomain

        }

    }





    <#
    .SYNOPSIS
        Set the current ACME order, edits an orders properties, or revokes an order's certificate.

    .DESCRIPTION
        Switch to a specific ACME order and edit its properties or revoke its certificate. Revoked certificate orders are not deleted and can be re-requested using Submit-Renewal or New-PACertificate.

    .PARAMETER MainDomain
        The primary domain for the order. For a SAN order, this was the first domain in the list when creating the order.

    .PARAMETER RevokeCert
        If specified, a request will be sent to the associated ACME server to revoke the certificate on this order. Clients may wish to do this if the certificate is decommissioned or the private key has been compromised. A warning will be displayed if the order is not currently valid or the existing certificate file can't be found.

    .PARAMETER Force
        If specified, confirmation prompts for certificate revocation will be skipped.

    .PARAMETER NoSwitch
        If specified, the currently selected order will not change. Useful primarily for bulk certificate revocation. This switch is ignored if no MainDomain is specified.

    .PARAMETER Plugin
        One or more validation plugin names to use for this order's challenges. If no plugin is specified, the DNS "Manual" plugin will be used. If the same plugin is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the order.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified Plugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER DnsAlias
        One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone. This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records. If the same alias is used for all domains in the order, you can just specify it once. Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

    .PARAMETER FriendlyName
        Modify the friendly name for the certificate and subsequent renewals. This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported. Must not be an empty string.

    .PARAMETER PfxPass
        Modify the PFX password for the certificate and subsequent renewals. When the PfxPassSecure parameter is specified, this parameter is ignored.

    .PARAMETER PfxPassSecure
        Modify the PFX password for the certificate and subsequent renewals using a SecureString value. When this parameter is specified, the PfxPass parameter is ignored.

    .PARAMETER Install
        Enables the Install switch for the order. Use -Install:$false to disable the switch on the order. This affects whether the module will automatically import the certificate to the Windows certificate store on subsequent renewals. It will not import the current certificate if it exists. Use Install-PACertificate for that purpose.

    .PARAMETER OCSPMustStaple
        If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

    .PARAMETER DnsSleep
        Number of seconds to wait for DNS changes to propagate before asking the ACME server to validate DNS challenges.

    .PARAMETER ValidationTimeout
        Number of seconds to wait for the ACME server to validate the challenges after asking it to do so. If the timeout is exceeded, an error will be thrown.

    .PARAMETER PreferredChain
        If the CA offers multiple certificate chains, prefer the chain with an issuer matching this Subject Common Name. If no match, the default offered chain will be used.

    .PARAMETER AlwaysNewKey
        If specified, the order will be configured to always generate a new private key during each renewal. Otherwise, the old key is re-used if it exists.

    .PARAMETER UseSerialValidation
        If specified, the names in the order will be validated individually rather than all at once. This can significantly increase the time it takes to process validations and should only be used for plugins that require it. The plugin's usage guide should indicate whether it is required.

    .EXAMPLE
        Set-PAOrder site1.example.com

        Switch to the specified domain's order.

    .EXAMPLE
        Set-PAOrder -RevokeCert

        Revoke the current order's certificate.

    .EXAMPLE
        Set-PAOrder -FriendlyName 'new friendly name'

        Edit the friendly name for the current order and certificate if it exists.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
