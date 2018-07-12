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
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DnsPlugin,
        [Parameter(ParameterSetName='Edit')]
        [hashtable]$PluginArgs,
        [Parameter(ParameterSetName='Edit')]
        [ValidateNotNullOrEmpty()]
        [string]$FriendlyName,
        [Parameter(ParameterSetName='Edit')]
        [ValidateNotNullOrEmpty()]
        [string]$PfxPass,
        [Parameter(ParameterSetName='Edit')]
        [switch]$Install,
        [Parameter(ParameterSetName='Edit')]
        [int]$DNSSleep,
        [Parameter(ParameterSetName='Edit')]
        [int]$ValidationTimeout,
        [Parameter(ParameterSetName='Edit')]
        [string]$PreferredChain
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        # throw an error if there's no current order and no MainDomain
        # passed in
        if (!$script:Order -and !$MainDomain) {
            throw "No ACME order configured. Run New-PAOrder or specify a MainDomain."
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
            Import-PAConfig 'Order'

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

            if ('DnsPlugin' -in $psbKeys -and
                ($null -eq $order.DnsPlugin -or $null -ne (Compare-Object $DnsPlugin $order.DnsPlugin))) {
                Write-Verbose "Setting DnsPlugin to $(($DnsPlugin -join ','))"
                $order.DnsPlugin = $DnsPlugin
                $saveChanges = $true
            }

            if ('PluginArgs' -in $psbKeys) {
                Write-Verbose "Updating plugin args for plugin(s) $(($order.DnsPlugin -join ','))"
                Export-PluginArgs $PluginArgs $order.DnsPlugin
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

            if ('DNSSleep' -in $psbKeys -and $DNSSleep -ne $order.DNSSleep) {
                Write-Verbose "Setting DNSSleep to $DNSSleep"
                $order.DNSSleep = $DNSSleep
                $saveChanges = $true
            }

            if ('ValidationTimeout' -in $psbKeys -and $ValidationTimeout -ne $order.ValidationTimeout) {
                Write-Verbose "Setting ValidationTimeout to $ValidationTimeout"
                $order.ValidationTimeout = $ValidationTimeout
                $saveChanges = $true
            }

            if ('PreferredChain' -in $psbKeys -and $PreferredChain -ne $order.PreferredChain) {
                Write-Verbose "Setting PreferredChain to $PreferredChain"
                if ('PreferredChain' -notin $order.PSObject.Properties.Name) {
                    $order | Add-Member -MemberType NoteProperty -Name 'PreferredChain' -Value $PreferredChain
                } else {
                    $order.PreferredChain = $PreferredChain
                }
                $saveChanges = $true
                $rewritePfx = $true
                $rewriteCer = $true
            }

            if ($saveChanges) {
                Write-Verbose "Saving order changes"
                $orderFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
                $order | ConvertTo-Json | Out-File (Join-Path $orderFolder 'order.json') -Force -EA Stop
            }

            $cert = Get-PACertificate $order.MainDomain
            if ($rewriteCer -and $cert) {
                Export-PACertFiles $order
            } elseif ($rewritePfx -and $cert) {
                Export-PACertFiles $order -PfxOnly
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
            $certFile = Join-Path (Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')) 'cert.cer'
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
                throw "Malformed certificate file. $certFile"
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
                $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            } catch { throw }
            Write-Debug "Response: $($response.Content)"

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

    .PARAMETER NoSwitch
        If specified, the currently selected order will not change. Useful primarily for bulk certificate revocation. This switch is ignored if no MainDomain is specified.

    .PARAMETER Force
        If specified, confirmation prompts for certificate revocation will be skipped.

    .PARAMETER FriendlyName
        Modify the friendly name for the certificate and subsequent renewals. This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported. Must not be an empty string.

    .PARAMETER PfxPass
        Modify the PFX password for the certificate and subsequent renewals.

    .PARAMETER Install
        Enables the Install switch for the order. Use -Install:$false to disable the switch on the order. This affects whether the module will automatically import the certificate to the Windows certificate store on subsequent renewals. It will not import the current certificate if it exists. Use Install-PACertificate for that purpose.

    .PARAMETER DNSSleep
        Number of seconds to wait for DNS changes to propagate before asking the ACME server to validate DNS challenges.

    .PARAMETER ValidationTimeout
        Number of seconds to wait for the ACME server to validate the challenges after asking it to do so. If the timeout is exceeded, an error will be thrown.

    .PARAMETER PreferredChain
        If the CA offers multiple certificate chains, prefer the chain with an issuer matching this Subject Common Name. If no match, the default offered chain will be used.

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
