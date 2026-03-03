function Publish-DnsPersistChallenge {
    [CmdletBinding(DefaultParameterSetName='FromOrder')]
    param(
        [Parameter(Mandatory,ParameterSetName='FromOrder',Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [Parameter(ParameterSetName='FromOrder',Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,ParameterSetName='Standalone',Position=0,ValueFromPipeline)]
        [string]$Domain,
        [Parameter(Mandatory,ParameterSetName='Standalone',Position=1)]
        [string]$IssuerDomainName,
        [Parameter(Mandatory,ParameterSetName='Standalone',Position=2)]
        [string]$AccountUri,
        [Parameter(Mandatory,ParameterSetName='Standalone')]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string]$Plugin,
        [Parameter(ParameterSetName='Standalone')]
        [hashtable]$PluginArgs,
        [switch]$AllowWildcard,
        [switch]$UseAllDomains,
        [DateTimeOffset]$PersistUntil
    )

    Begin {
        # Make sure we have an account if we're running in the FromOrder parameter set.
        if ('FromOrder' -eq $PSCmdlet.ParameterSetName) {
             try {
                if (-not $Account) {
                    if (-not ($Account = Get-PAAccount)) {
                        throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
                    }
                }
            }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
            $AccountUri = $Account.location
        }

        # initialize a deferred collection object so we can build up the list of challenges
        # to publish as we process the orders and then publish them all at once at the end.
        $chalCollection = [Collections.Generic.List[pscustomobject]]::new()
    }

    Process {

        if ('FromOrder' -eq $PSCmdlet.ParameterSetName) {

            # extract the required parameters from the order object
            $auths = $Order | Get-PAAuthorization
            $pArgs = $Order | Get-PAPluginArgs

            # loop through the auths by index so we can correlate them to the associated plugin on the order
            for ($i=0; $i -lt $auths.Count; $i++) {
                $fqdn = $auths[$i].fqdn

                if ($fqdn.StartsWith('*.')) {
                    # Ignore wildcards unless -AllowWildcard is specified.
                    if (-not $AllowWildcard) {
                        Write-Warning "Skipping dns-persist-01 for $fqdn because -AllowWildcard was not specified."
                        continue
                    }
                    # strip the wildcard characters for the rest of the processing since the validation record doesn't need them.
                    $fqdn = $fqdn.Substring(2)
                }

                $challenge = $auths[$i].challenges | Where-Object { $_.type -eq 'dns-persist-01' }
                if (-not $challenge) {
                    Write-Warning "Authz contains no dns-persist-01 challenge for $fqdn. Skipping."
                    continue
                }
                $issuers = $challenge.'issuer-domain-names'

                # Sanity check issuer-domain-names.
                # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-00.html#section-3.1
                if (-not $issuers -or $issuers.Length -eq 0) {
                    Write-Warning "dns-persist-01 challenge for $fqdn has no issuer domain names. Skipping."
                    continue
                }
                if ($issuers.Length -gt 10) {
                    Write-Warning "dns-persist-01 challenge for $fqdn has more than 10 issuer domain names. Clients must reject this. Skipping."
                    continue
                }

                # "The order of names in the array has no significance."
                # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-00.html#section-7.6
                # So sort them to make it more likely that we get the same value for each challenge on each run.
                $issuers = @($issuers | Sort-Object)

                # correlate the plugin args to the auth by index or use the last one available.
                if ($Order.Plugin.Count -gt $i) {
                    $plugin = $Order.Plugin[$i]
                } else {
                    $plugin = $Order.Plugin[-1]
                }

                $chalCollection.Add([pscustomobject]@{
                    fqdn = $fqdn
                    issuer = $issuers[0]
                    plugin = $plugin
                    pArgs = $pArgs
                })
            }

        } else {

            # sanitize the $Domain if it was passed in as a wildcard on accident
            if ($Domain -and $Domain.StartsWith('*.')) {
                Write-Warning "Stripping wildcard characters from $Domain. Not required for publishing."
                $Domain = $Domain.Substring(2)
            }

            $chalCollection.Add([pscustomobject]@{
                fqdn = $Domain
                issuer = $IssuerDomainName
                plugin = $Plugin
                pArgs = $PluginArgs
            })

        }

    }

    End {

        # Sort FQDNs by reverse label order so the most generic (example.com) comes first
        # and filter duplicate fqdns due to wildcard trimming.
        $chals = $chalCollection.ToArray() | Sort-Object {$a=$_.fqdn.Split('.'); [array]::Reverse($a); $a -join '.'} -Unique

        # filter out any challenges that would be covered by a previous record if wildcards are allowed
        # and -UseAllDomains was not specified
        $lastFqdn = $null
        $chals = foreach ($chal in $chals) {
            if ($chal.fqdn -like "*.$lastFqdn" -and $AllowWildcard -and -not $UseAllDomains) {
                Write-Verbose "Skipping $($chal.fqdn) because it's a wildcard match for $lastFqdn and should be covered by the same TXT record."
                continue
            }
            Write-Output $chal
            $lastFqdn = $chal.fqdn
        }

        # process what's left by plugin
        $chals | Group-Object plugin | ForEach-Object {

            # dot source the plugin file
            $pluginDetail = $script:Plugins.($_.Name)
            Write-Verbose ($pluginDetail | convertto-json)
            . $pluginDetail.Path

            # process the group by unique pArgs
            $_.Group | Group-Object pArgs | ForEach-Object {
                $pArgs = $_.Group[0].pArgs

                foreach ($chal in $_.Group) {

                    Write-Verbose "Publishing dns-persist-01 challenge for $($chal.fqdn) using Plugin $($chal.plugin)."

                    $recordName = "_validation-persist.$($chal.fqdn)".TrimEnd('.')

                    # build the TXT value based on the input parameters
                    $txtValue = '{0}; accounturi={1}' -f $chal.issuer, $AccountUri
                    if ($AllowWildcard) {
                        $txtValue += '; policy=wildcard'
                    }
                    if ($PersistUntil) {
                        $txtValue += '; persistUntil={0}' -f $PersistUntil.ToUnixTimeSeconds()
                    }
                    $txtValue = '"{0}"' -f $txtValue

                    # call the function with the required parameters and splatting the rest
                    Write-Debug "Calling $($chal.plugin) plugin to add $recordName TXT with value $txtValue"
                    Add-DnsTxt -RecordName $recordName -TxtValue $txtValue @pArgs
                }

                # Save the changes for this plugin and pArgs combination
                Write-Verbose "Finalizing record changes for plugin $($pluginDetail.Name)."
                Save-DnsTxt @pArgs
            }

        }

    }

}
