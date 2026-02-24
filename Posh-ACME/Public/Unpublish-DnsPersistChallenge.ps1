function Unpublish-DnsPersistChallenge {
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
    }

    Process {

        if ('FromOrder' -eq $PSCmdlet.ParameterSetName) {

            # extract the required parameters from the order object
            $auths = $Order | Get-PAAuthorization
            $pArgs = $Order | Get-PAPluginArgs

            # loop through the auths by index so we can correlate them to the associated plugin on the order
            $chals = for ($i=0; $i -lt $auths.Count; $i++) {
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

                [pscustomobject]@{
                    fqdn = $fqdn
                    issuer = $issuers[0]
                    plugin = $plugin
                    pArgs = $pArgs
                }
            }

            # Sort FQDNs by reverse label order so the most generic (example.com) comes first
            # and filter duplicate fqdns due to wildcard trimming.
            $chals = $chals | Sort-Object {$a=$_.fqdn.Split('.'); [array]::Reverse($a); $a -join '.'} -Unique

            $lastFqdn = $null
            foreach ($chal in $chals) {
                # skip if a previous wildcard enabled record would cover this domain and -UseAllDomains was not specified
                if ($chal.fqdn -like "*.$lastFqdn" -and $AllowWildcard -and -not $UseAllDomains) {
                    Write-Verbose "Skipping $($chal.fqdn) because it's a wildcard match for $lastFqdn and should be covered by the same TXT record."
                    continue
                }

                $publishArgs = @{
                    Domain = $chal.fqdn
                    IssuerDomainName = $chal.issuer
                    AccountUri = $AccountUri
                    Plugin = $chal.plugin
                    PluginArgs = $chal.pArgs
                    AllowWildcard = $AllowWildcard
                }
                if ($PersistUntil) {
                    $publishArgs.PersistUntil = $PersistUntil
                }
                Unpublish-DnsPersistChallenge @publishArgs
                $lastFqdn = $chal.fqdn
            }

        } else {

            # sanitize the $Domain if it was passed in as a wildcard on accident
            if ($Domain -and $Domain.StartsWith('*.')) {
                Write-Warning "Stripping wildcard characters from domain name. Not required for publishing."
                $Domain = $Domain.Substring(2)
            }

            # build the TXT value based on the input parameters
            $txtValue = '{0}; accounturi={1}' -f $IssuerDomainName, $AccountUri
            if ($AllowWildcard) {
                $txtValue += '; policy=wildcard'
            }
            if ($PersistUntil) {
                $txtValue += '; persistUntil={0}' -f $PersistUntil.ToUnixTimeSeconds()
            }
            $txtValue = '"{0}"' -f $txtValue

            # dot source the plugin file
            $pluginDetail = $script:Plugins.$Plugin
            . $pluginDetail.Path

            # All plugins in $script:Plugins should have been validated during module
            # load. So we're not going to do much plugin-specific validation here.
            Write-Verbose "Unpublishing dns-persist-01 challenge for $Domain using Plugin $Plugin."

            $recordName = "_validation-persist.$($Domain)".TrimEnd('.')

            # call the function with the required parameters and splatting the rest
            Write-Debug "Calling $Plugin plugin to remove $recordName TXT with value $txtValue"
            Remove-DnsTxt -RecordName $recordName -TxtValue $txtValue @PluginArgs

        }

    }

}
