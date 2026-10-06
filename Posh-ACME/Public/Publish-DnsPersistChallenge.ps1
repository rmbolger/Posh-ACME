function Publish-DnsPersistChallenge {
    [CmdletBinding(DefaultParameterSetName='PreProvision')]
    param(
        [Parameter(Mandatory,ParameterSetName='FromOrder',Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [Parameter(Mandatory,ParameterSetName='PreProvision',Position=0,ValueFromPipeline)]
        [Parameter(Mandatory,ParameterSetName='PreProvisionExplicit',Position=0,ValueFromPipeline)]
        [Parameter(Mandatory,ParameterSetName='Advanced',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Domain,
        [Parameter(Mandatory,ParameterSetName='PreProvision')]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,ParameterSetName='PreProvisionExplicit')]
        [string]$AccountUri,
        [Parameter(Mandatory,ParameterSetName='PreProvisionExplicit')]
        [string]$KeyThumbprint,
        [Parameter(Mandatory,ParameterSetName='Advanced',ValueFromPipelineByPropertyName)]
        [string]$HashedAccountUri,
        [Parameter(ParameterSetName='PreProvision')]
        [Parameter(ParameterSetName='PreProvisionExplicit')]
        [Parameter(ParameterSetName='FromOrder')]
        [string]$AccountHashPrefix,
        [Parameter(ParameterSetName='PreProvision')]
        [Parameter(ParameterSetName='PreProvisionExplicit')]
        [Parameter(ParameterSetName='FromOrder')]
        [Parameter(ParameterSetName='Advanced',ValueFromPipelineByPropertyName)]
        [string]$IssuerDomainName,
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string[]]$Plugin,
        [hashtable]$PluginArgs,
        [Parameter(ParameterSetName='PreProvision')]
        [Parameter(ParameterSetName='PreProvisionExplicit')]
        [Parameter(ParameterSetName='FromOrder')]
        [Parameter(ParameterSetName='Advanced',ValueFromPipelineByPropertyName)]
        [switch]$AllowWildcard,
        [Parameter(ParameterSetName='PreProvision')]
        [Parameter(ParameterSetName='PreProvisionExplicit')]
        [Parameter(ParameterSetName='FromOrder')]
        [Parameter(ParameterSetName='Advanced',ValueFromPipelineByPropertyName)]
        [Nullable[DateTimeOffset]]$PersistUntil,
        [switch]$NoAutoWildcard,
        [Parameter(ParameterSetName='PreProvision')]
        [Parameter(ParameterSetName='PreProvisionExplicit')]
        [Parameter(ParameterSetName='FromOrder')]
        [switch]$NoDomainCorrelationMitigation
    )

    Begin {
        trap { $PSCmdlet.ThrowTerminatingError($_) }

        $server = Get-PAServer

        # Set the Manual plugin if no plugin was specified and we are not in the FromOrder param set
        if (-not $Plugin -and 'FromOrder' -ne $PSCmdlet.ParameterSetName) {
            $Plugin = 'Manual'
        }

        $idn = [Globalization.IdnMapping]::new()

        # get the current account for later if it wasn't passed in
        if (-not $Account) {
            $Account = Get-PAAccount
        }

        # initialize a deferred collection object so we can build up the list of challenges
        # to publish as we process the pipeline inputs and publish them all at the end
        $chalCollection = [Collections.Generic.List[pscustomobject]]::new()
    }

    Process {

        # Try to grab server published things we may need if they weren't explicitly provided
        if (-not $IssuerDomainName -and 'FromOrder' -ne $PSCmdlet.ParameterSetName) {
            # issuerDomainName is needed for everything other than the FromOrder parameter set
            # which can get it from the challenge object
            if (-not $server) {
                throw "IssuerDomainName not specified and no ACME server is selected. Try running Set-PAServer first."
            }
            # "The order of names in the array has no significance."
            # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-02.html#section-7.6
            # So sort them to make it more likely that we get the same value for each challenge on each run.
            $IssuerDomainName = $server.meta.issuerDomainNames | Sort-Object | Select-Object -First 1
            if (-not $IssuerDomainName) {
                throw "IssuerDomainName not specified and the current ACME server does not publish the required value in the directory metadata."
            }
        }
        if (-not $AccountHashPrefix -and 'Advanced' -ne $PSCmdlet.ParameterSetName) {
            # accountHashPrefix is needed for everything other than the Advanced parameter set
            if (-not $server) {
                throw "AccountHashPrefix not specified and no ACME server is selected. Try running Set-PAServer first."
            }
            $AccountHashPrefix = $server.meta.accountHashPrefix
            if (-not $AccountHashPrefix) {
                throw "AccountHashPrefix not specified and the current ACME server does not publish the required value in the directory metadata."
            }
        }

        # Build the list of challenges to publish from the Domains and other properties of the order.
        if ('FromOrder' -eq $PSCmdlet.ParameterSetName) {

            # deal with plugin params potentially being overridden by explicit parameters
            if ('Plugin' -notin $PSBoundParameters.Keys) {
                $Plugin = $Order.Plugin
            } else {
                Write-Verbose "Overriding order Plugin with explicit parameter."
            }
            if ('PluginArgs' -notin $PSBoundParameters.Keys) {
                $PluginArgs = $Order | Get-PAPluginArgs
            } else {
                Write-Verbose "Overriding order PluginArgs with explicit parameter."
            }

            # loop through the auths by index so we can correlate them to the associated plugin
            $auths = @($Order | Get-PAAuthorization)
            for ($i=0; $i -lt $auths.Count; $i++) {
                $fqdn = $auths[$i].fqdn
                $addWildcard = $false

                # skip any auths that don't have a dns-persist-01 challenge
                $challenge = $auths[$i].challenges | Where-Object { $_.type -eq 'dns-persist-01' }
                if (-not $challenge) {
                    Write-Warning "Authz for $fqdn contains no dns-persist-01 challenge. Skipping."
                    continue
                }

                # skip challenges missing an issuer unless it was overridden
                $issuer = $IssuerDomainName
                if (-not $issuer) {
                    $issuer = Get-IssuerFromChallenge $challenge
                    if (-not $issuer) {
                        Write-Warning "Unable to determine issuer domain name from dns-persist-01 challenge for $fqdn."
                        continue
                    }
                }

                if ($fqdn.StartsWith('*.', [StringComparison]::Ordinal)) {
                    # Add the wildcard flag unless -NoAutoWildcard is specified and -AllowWildcard is not specified.
                    if ($NoAutoWildcard -and -not $AllowWildcard) {
                        Write-Warning "Skipping $fqdn because -NoAutoWildcard was specified."
                        continue
                    } else {
                        $addWildcard = $true
                    }
                    # strip the wildcard characters for the rest of the processing since the validation record doesn't need them.
                    $fqdn = $fqdn.Substring(2)
                }
                if ($AllowWildcard) {
                    $addWildcard = $true
                }

                $fqdn = $idn.GetAscii($fqdn.Trim().TrimEnd('.').ToLowerInvariant().Normalize([Text.NormalizationForm]::FormC)).ToLowerInvariant()

                # correlate the plugin args to the auth by index or use the last one available.
                if ($Plugin.Count -gt $i) {
                    $p = $Plugin[$i]
                } else {
                    $p = $Plugin[-1]
                }

                # generate the hashed account URI for the challenge
                $getUriParams = @{
                    Domain            = $fqdn
                    AccountHashPrefix = $AccountHashPrefix
                    AccountUri        = $Account.location
                    KeyThumbprint     = $Account.thumbprint
                }
                if ($NoDomainCorrelationMitigation) {
                    Write-Verbose "Generating hashed accountUri with no domain correlation mitigation."
                    $getUriParams.Domain = '*'
                }
                $hashAcctUri = Get-DnsPersistAccountUri @getUriParams

                # add the challenge information to the collection
                $chalCollection.Add([pscustomobject]@{
                    fqdn          = $fqdn
                    hashAcctUri   = $hashAcctUri
                    issuer        = $issuer
                    plugin        = $p
                    pArgs         = $PluginArgs
                    addWildcard   = $addWildcard
                    persistUntil  = $PersistUntil
                    fromAcctUri   = $Account.location
                    fromAcctThumb = $Account.thumbprint
                })
            }

            # advance to next pipeline item
            return
        }

        # All other parameter sets have an explicit list of domains to process.
        for ($i=0; $i -lt $Domain.Count; $i++) {

            $fqdn = $Domain[$i].Trim().TrimEnd('.')

            $addWildcard = $false
            if ($fqdn.StartsWith('*.', [StringComparison]::Ordinal)) {
                # Add the wildcard flag unless -NoAutoWildcard is specified and -AllowWildcard is not specified.
                if ($NoAutoWildcard -and -not $AllowWildcard) {
                    Write-Warning "Skipping $fqdn because -NoAutoWildcard was specified."
                    continue
                } else {
                    $addWildcard = $true
                }
                # strip the wildcard characters for the rest of the processing since the validation record doesn't need them.
                $fqdn = $fqdn.Substring(2)
            }
            if ($AllowWildcard) {
                $addWildcard = $true
            }

            $fqdn = $idn.GetAscii($fqdn.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormC)).ToLowerInvariant()

            # correlate the plugin args to the auth by index or use the last one available.
            if ($Plugin.Count -gt $i) {
                $p = $Plugin[$i]
            } else {
                $p = $Plugin[-1]
            }

            # The $HashedAccountUri is only available in the Advanced parameter set and mandatory.
            # Its existence means we should use it as-is, but also means we don't know the account
            # location or thumbprint of the account used to generate it.
            $hashAcctUri = $HashedAccountUri
            $fromAcctUri = ''
            $fromAcctThumb = ''

            # But if it doesn't exist, all we're left with are the PreProvision* parameter sets where
            # we need to generate it using Get-DnsPersistAccountUri.
            if (-not $hashAcctUri) {

                # Build the call to Get-DnsPersistAccountUri based the parameter set.
                $getUriParams = @{
                    Domain            = $fqdn
                    AccountHashPrefix = $AccountHashPrefix
                }
                if ($NoDomainCorrelationMitigation) {
                    Write-Verbose "Generating hashed accountUri with no domain correlation mitigation."
                    $getUriParams.Domain = '*'
                }
                if ('PreProvision' -eq $PSCmdlet.ParameterSetName) {
                    $fromAcctUri = $Account.location
                    $fromAcctThumb = $Account.thumbprint
                    # pass through the account object
                    $getUriParams.Account = $Account
                } else { # PreProvisionExplicit
                    # pass through the explicit account URI and key thumbprint
                    $getUriParams.AccountUri    = $fromAcctUri   = $AccountUri
                    $getUriParams.KeyThumbprint = $fromAcctThumb = $KeyThumbprint
                }
                $hashAcctUri = Get-DnsPersistAccountUri @getUriParams
            }

            # add the challenge information to the collection
            $chalCollection.Add([pscustomobject]@{
                fqdn          = $fqdn
                hashAcctUri   = $hashAcctUri
                issuer        = $IssuerDomainName
                plugin        = $p
                pArgs         = $PluginArgs
                addWildcard   = $addWildcard
                persistUntil  = $PersistUntil
                fromAcctUri   = $fromAcctUri
                fromAcctThumb = $fromAcctThumb
            })
        }

    }

    End {

        # sort challenges by issuer and domain
        $orderedChals = $chalCollection.ToArray() |
            Sort-Object -Property issuer,{
                $a=$_.fqdn.Split('.'); [array]::Reverse($a); $a -join '.'
            },hashAcctUri

        # process challenges by plugin
        $modified = $orderedChals | Group-Object plugin | ForEach-Object {

            # dot source the plugin file
            $pluginDetail = $script:Plugins.($_.Name)
            Write-Verbose "Loading plugin $($pluginDetail.Name)"
            . $pluginDetail.Path

            # process the group by unique pArgs
            $_.Group | Group-Object pArgs | ForEach-Object {
                $pArgs = $_.Group[0].pArgs

                foreach ($chal in $_.Group) {

                    Write-Verbose "Publishing dns-persist-01 challenge for $($chal.fqdn) using Plugin $($chal.plugin)."

                    $recordName = "_validation-persist.$($chal.fqdn)"

                    # build the TXT value based on the input parameters
                    $txtValue = '{0}; accounturi={1}' -f $chal.issuer, $chal.hashAcctUri
                    if ($chal.addWildcard) {
                        $txtValue += '; policy=wildcard'
                    }
                    if ($chal.persistUntil) {
                        $txtValue += '; persistUntil={0}' -f $chal.persistUntil.ToUnixTimeSeconds()
                    }
                    $txtValue = '"{0}"' -f $txtValue

                    # call the function with the required parameters and splatting the rest
                    Write-Debug "Calling $($chal.plugin) plugin to add $recordName TXT with value $txtValue"
                    Add-DnsTxt -RecordName $recordName -TxtValue $txtValue @pArgs

                    [pscustomobject]@{
                        fqdn        = $chal.fqdn
                        issuer      = $chal.issuer
                        hashAcctUri = $chal.hashAcctUri
                        addWildcard = $chal.addWildcard
                        persistUntil = if ($chal.persistUntil) { $chal.persistUntil.ToUnixTimeSeconds().ToString() } else { $null }
                        fromAcctUri  = $chal.fromAcctUri
                        fromAcctThumb = $chal.fromAcctThumb
                    }
                }

                # Save the changes for this plugin and pArgs combination
                Write-Verbose "Finalizing record changes for plugin $($pluginDetail.Name)."
                Save-DnsTxt @pArgs
            }

        }

        # Append the published challenges to the local cache if they don't already exist
        $pubCachePath = Join-Path (Get-ConfigRoot) 'PersistedChallenges.json'
        if (Test-Path $pubCachePath) {
            $existing = Get-Content $pubCachePath -Raw | ConvertFrom-Json
            $existing = @($existing)
        } else {
            $existing = @()
        }
        $toSave = $modified | Where-Object {
            $fqdn        = $_.fqdn
            $issuer      = $_.issuer
            $hashAcctUri = $_.hashAcctUri
            $addWildcard = $_.addWildcard
            $expires = $_.persistUntil

            -not ($existing | Where-Object {
                $_.fqdn -eq $fqdn -and
                $_.issuer -eq $issuer -and
                $_.hashAcctUri -eq $hashAcctUri -and
                $_.addWildcard -eq $addWildcard -and
                $_.persistUntil -eq $expires
            })
        }
        $existing += $toSave
        ConvertTo-Json @($existing) -Depth 5 | Set-Content $pubCachePath
    }

}
