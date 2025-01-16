function Set-PAOrder {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Edit')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable','')]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
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
        [ValidateRange(0, 3650)]
        [int]$LifetimeDays,
        [Parameter(ParameterSetName='Edit')]
        [string[]]$DnsAlias,
        [Parameter(ParameterSetName='Edit')]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$NewName,
        [Parameter(ParameterSetName='Edit')]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,
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
        [switch]$UseModernPfxEncryption,
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
        [switch]$UseSerialValidation,
        [Parameter(ParameterSetName='Edit')]
        [string]$Profile
    )

    Begin {
        try {
            # Make sure we have an account configured
            if (-not ($acct = Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

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

        # There are 3 types of calls the user might be making here.
        # - order switch
        # - order switch and edit/revoke
        # - edit/revoke only (possibly bulk via pipeline)
        # The default is to switch orders. So we have a -NoSwitch parameter to
        # indicate a non-switching revocation. But there's a chance they could forget
        # to use it for a bulk update. For now, we'll just let it happen and switch
        # to whatever order came through the pipeline last.

        # Make sure we have a distinct order to work with
        if ($Name) {
            $order = Get-PAOrder -Name $Name
            if (-not $order) {
                Write-Error "No order found matching Name '$Name'"
                return
            }
        }
        elseif ($MainDomain) {
            # They only specified MainDomain which means there could be multiple matches. But
            # we want to avoid letting users accidentally modify the wrong order. So error if
            # there are multiple matches.
            $order = Get-PAOrder -List | Where-Object { $_.MainDomain -eq $MainDomain }
            if (-not $order) {
                Write-Error "No order found matching MainDomain '$MainDomain'."
                return
            }
            elseif ($order -and $order.Count -gt 1) {
                Write-Error "Multiple orders found for MainDomain '$MainDomain'. Please specify Name as well."
                return
            }
        }
        else {
            # get the current order if it exists
            $order = Get-PAOrder
            if (-not $order) {
                Write-Error "No ACME order configured. Run New-PAOrder or specify a Name or MainDomain."
                return
            }
        }

        # check if the specified order matches the current order
        $modCurrentOrder = ($script:Order -and $script:Order.Name -eq $order.Name)

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
                Export-PluginArgs -Order $order -PluginArgs $PluginArgs
            }

            if ('DnsAlias' -in $psbKeys) {
                Write-Verbose "Setting DnsAlias to $($DnsAlias -join ',')"
                $order.DnsAlias = @($DnsAlias)
                $saveChanges = $true
            }

            if ('Subject' -in $psbKeys -and $Subject -ne $order.Subject) {
                Write-Verbose "Setting Subject to '$Subject'"
                Write-Warning "Changing the value of Subject only affects future certificates generated with this order. It can not change the state of an existing certificate."
                $order.Subject = $Subject
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

            if ('Profile' -in $psbKeys -and $Profile -ne $order.Profile) {
                if ($Profile -in (Get-PAProfile).Profile) {
                    Write-Verbose "Setting Profile to $Profile"
                    $order | Add-Member 'Profile' $Profile -Force
                    $saveChanges = $true
                    $rewritePfx = $false
                    $rewriteCer = $false
                } else {
                    Write-Warning "Profile '$Profile' is not currently supported on this ACME server. Ignoring profile selection."
                }
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

            if ('LifetimeDays' -in $psbKeys -and $LifetimeDays -ne $order.LifetimeDays) {
                Write-Verbose "Setting LifetimeDays to $LifetimeDays"
                $order.LifetimeDays = $LifetimeDays
                $saveChanges = $true
            }

            if ('UseModernPfxEncryption' -in $psbKeys -and
                (-not $order.UseModernPfxEncryption -or $UseModernPfxEncryption.IsPresent -ne $order.UseModernPfxEncryption)
            ) {
                Write-Verbose "Setting UseModernPfxEncryption to $($UseModernPfxEncryption.IsPresent)"
                $order | Add-Member 'UseModernPfxEncryption' $UseModernPfxEncryption.IsPresent -Force
                $saveChanges = $true
                $rewritePfx = $true
            }

            if ($saveChanges) {
                Write-Verbose "Saving order changes"
                Update-PAOrder $order -SaveOnly
            }

            # re-export certs if necessary
            if ($rewriteCer -or $rewritePfx) {
                $cert = $order | Get-PACertificate
                if ($rewriteCer -and $cert) {
                    Export-PACertFiles $order
                } elseif ($rewritePfx -and $cert) {
                    Export-PACertFiles $order -PfxOnly
                }
            }

            # deal with potential name change
            if ($NewName -and $NewName -ne $order.Name) {

                $newFolder = Join-Path $acct.Folder $NewName
                if (Test-Path $newFolder) {
                    Write-Error "Failed to rename PAOrder '$($order.Name)'. The path '$newFolder' already exists."
                } else {
                    try {
                        # rename the dir folder
                        Write-Debug "Renaming '$($order.Name)' order folder to $newFolder"
                        Rename-Item $order.Folder $newFolder -EA Stop

                        # update the id/Folder in memory
                        $order.Name = $NewName
                        $order.Folder = $newFolder
                    }
                    catch {
                        Write-Error $_
                    }
                }
            }

            # update the current order ref if necessary
            $curOrderFile = (Join-Path $acct.Folder 'current-order.txt')
            if ($modCurrentOrder -or -not $NoSwitch) {
                if ($order.Name -ne (Get-Content $curOrderFile -EA Ignore)) {
                    Write-Debug "Updating current-order.txt"
                    $order.Name | Out-File $curOrderFile -Force -EA Stop
                }
                $script:Order = $order
            }


        } else {
            # RevokeCert was specified

            # make sure the order has a cert to revoke and that it's not already expired
            if (-not $order.CertExpires) {
                Write-Warning "Unable to revoke certificate for order '$($order.Name)'. No cert found to revoke."
                return
            }
            if ((Get-DateTimeOffsetNow) -ge ([DateTimeOffset]::Parse($order.CertExpires))) {
                Write-Warning "Unable to revoke certificate for order '$($order.Name)'. Cert already expired."
                return
            }

            # make sure the cert file actually exists
            $certFile = Join-Path $order.Folder 'cert.cer'
            if (-not (Test-Path $certFile -PathType Leaf)) {
                Write-Warning "Unable to revoke certificate. $certFile not found."
                return
            }

            # confirm revocation unless -Force was used
            if (-not $Force) {
                if (-not $PSCmdlet.ShouldContinue("Are you sure you wish to revoke the certificate for order '$($order.Name)'?",
                "Revoking a certificate is irreversible and may immediately break any services using it.")) {
                    Write-Verbose "Revocation aborted for order '$($order.Name)'."
                    return
                }
            }

            Write-Verbose "Revoking certificate for order '$($order.Name)'."

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
            Update-PAOrder $order

        }

    }
}
