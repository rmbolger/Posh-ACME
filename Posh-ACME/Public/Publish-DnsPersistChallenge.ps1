function Publish-DnsPersistChallenge {
    [CmdletBinding(DefaultParameterSetName='FromOrder')]
    param(
        [Parameter(Mandatory,ParameterSetName='FromOrder',Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [Parameter(Mandatory,ParameterSetName='Standalone',Position=0,ValueFromPipeline)]
        [string[]]$Domain,
        [Parameter(Mandatory,ParameterSetName='Standalone',Position=1)]
        [string]$AccountUri,
        [Parameter(Mandatory,ParameterSetName='Standalone',Position=2)]
        [string]$IssuerDomainName,
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
                if (-not ($Account = Get-PAAccount)) {
                    throw "No current account selected. Try running Set-PAAccount first."
                }
            }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # initialize a deferred collection object so we can build up the list of challenges
        # to publish as we process the orders and then publish them all at once at the end.
        $chalCollection = [Collections.Generic.List[pscustomobject]]::new()
    }

    Process {

        if ('FromOrder' -eq $PSCmdlet.ParameterSetName) {

            # extract the required parameters from the order object
            $auths = @($Order | Get-PAAuthorization)
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
                $issuer = Get-IssuerFromChallenge $challenge
                if (-not $issuer) {
                    Write-Warning "Unable to determine issuer domain name from dns-persist-01 challenge."
                    continue
                }

                # correlate the plugin args to the auth by index or use the last one available.
                if ($Order.Plugin.Count -gt $i) {
                    $plugin = $Order.Plugin[$i]
                } else {
                    $plugin = $Order.Plugin[-1]
                }

                # Sanitize the account URI for draft-00 challenges until implementations support the newer draft and include it.
                if (-not $challenge.accounturi) {
                    Write-Warning "dns-persist-01 challenge for $fqdn is missing accounturi. Might be based on draft-00. Using account URI from account object instead."
                    $challenge | Add-Member accounturi $Account.location -Force
                }

                $chalCollection.Add([pscustomobject]@{
                    fqdn = $fqdn
                    accounturi = $challenge.accounturi
                    issuer = $issuer
                    plugin = $plugin
                    pArgs = $pArgs
                })
            }

        } else {

            foreach ($d in $Domain) {
                # sanitize the domain if it was passed in as a wildcard on accident
                if ($d -and $d.StartsWith('*.')) {
                    Write-Warning "Stripping wildcard characters from $d. Not required for publishing."
                    $d = $d.Substring(2)
                }

                $chalCollection.Add([pscustomobject]@{
                    fqdn = $d
                    accounturi = $AccountUri
                    issuer = $IssuerDomainName
                    plugin = $Plugin
                    pArgs = $PluginArgs
                })

            }

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
            Write-Verbose "Loading plugin $($pluginDetail.Name)"
            . $pluginDetail.Path

            # process the group by unique pArgs
            $_.Group | Group-Object pArgs | ForEach-Object {
                $pArgs = $_.Group[0].pArgs

                foreach ($chal in $_.Group) {

                    Write-Verbose "Publishing dns-persist-01 challenge for $($chal.fqdn) using Plugin $($chal.plugin)."

                    $recordName = "_validation-persist.$($chal.fqdn)".TrimEnd('.')

                    # build the TXT value based on the input parameters
                    $txtValue = '{0}; accounturi={1}' -f $chal.issuer, $chal.accounturi
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
