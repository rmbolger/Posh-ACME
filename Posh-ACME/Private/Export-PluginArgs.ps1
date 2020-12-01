function Export-PluginArgs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(Mandatory,Position=1)]
        [string[]]$Plugin,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$PluginArgs,
        [switch]$IgnoreExisting
    )

    # In this function, we're trying to merge the specified plugin args with the existing set
    # of saved plugin arg data on disk. But some plugins have parameter sets that can
    # end up causing AmbiguousParameterSet errors if we just naively merge all new args.
    # So essentially what we're going to do is this for each specified plugin:
    # - query all supported args
    # - if any $PluginArgs match
    #   - check for saved plugin args that match and remove them
    # - add the new args to the saved data
    #
    # This should allow you to do something like add names to an existing cert where the new names
    # utilize a different plugin than the previous ones and only need to specify the new plugin's
    # parameters in $PluginArgs.

    Begin {
        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {
        trap { $PSCmdlet.ThrowTerminatingError($PSItem) }

        Write-Debug "Exporting plugin args for $MainDomain with plugins $(($Plugin -join ','))"

        # throw an error if an order isn't found matching MainDomain
        if (-not ($order = Get-PAOrder $MainDomain)) {
            throw "No ACME order found for $MainDomain."
        }

        $pData = @{}
        if (-not $IgnoreExisting) {
            $pData = Get-PAPluginArgs $order.MainDomain
        }

        # define the set of parameter names to ignore
        $ignoreParams = @('RecordName','TxtValue','Url','Body') +
            [Management.Automation.PSCmdlet]::CommonParameters +
            [Management.Automation.PSCmdlet]::OptionalCommonParameters

        # $Plugin will most often come with duplicates after being called from Submit-ChallengeValidation
        # So grab just the unique set.
        $uniquePlugins = @($Plugin | Sort-Object -Unique)

        # Get all of the plugin specific parameter names for the current plugin list
        $paramNames = foreach ($p in $uniquePlugins) {

            Write-Debug "Attempting to load plugin $p"

            $pluginDetail = $script:Plugins.$p
            if (-not $pluginDetail) {
                Write-Error "$p plugin not found or was invalid."
                continue
            }

            # dot source the plugin file
            . $pluginDetail.Path

            # grab a reference to the appropriate Add command
            if ('dns-01' -eq $pluginDetail.ChallengeType) {
                $cmd = Get-Command Add-DnsTxt
            } else {
                $cmd = Get-Command Add-HttpChallenge
            }

            # return the set of non-common param names
            $cmd.Parameters.Keys | Where-Object {
                ($_ -notin $ignoreParams) -and
                ($true -notin $cmd.Parameters[$_].Attributes.ValueFromRemainingArguments)
            }
        }

        # Remove any old args that may conflict with the new ones
        foreach ($key in @($pData.Keys)) {
            if ($key -in $paramNames) {
                Write-Debug "Removing old value for $key"
                $pData.Remove($key)
            }
        }

        # Add new args to the old data
        foreach ($key in ($PluginArgs.Keys | Where-Object { $_ -in $paramNames })) {
            Write-Debug "Adding new value for $key"
            $pData.$key = $PluginArgs.$key
        }

        # Now we need to export the merged object as JSON
        # but we have to pre-serialize things like SecureString and PSCredential
        # first because ConvertTo-Json can't deal with those natively.

        # determine whether we're using a custom key
        $encParam = @{}
        if (-not [String]::IsNullOrEmpty($acct.sskey)) {
            $encParam.Key = $acct.sskey | ConvertFrom-Base64Url -AsByteArray
        }

        $pDataSafe = @{}
        foreach ($key in $pData.Keys) {
            if ($pData.$key -is [securestring]) {
                $pDataSafe.$key = [pscustomobject]@{
                    origType = 'securestring'
                    value = $pData.$key | ConvertFrom-SecureString @encParam
                }
            }
            elseif ($pData.$key -is [pscredential]) {
                $pDataSafe.$key = [pscustomobject]@{
                    origType = 'pscredential'
                    user = $pData.$key.Username
                    pass = $pData.$key.Password | ConvertFrom-SecureString @encParam
                }
            }
            else {
                # for now, assume everything else is safe to auto serialize
                $pDataSafe.$key = $pData.$key
            }
        }

        # build the path to the existing plugin data file and export it
        $orderFolder = $order | Get-OrderFolder
        $pDataFile = Join-Path $orderFolder 'pluginargs.json'
        $pDataSafe | ConvertTo-Json -Depth 10 | Out-File $pDataFile -Encoding utf8
    }

}
