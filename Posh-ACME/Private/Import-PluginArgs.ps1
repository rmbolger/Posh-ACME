function Import-PluginArgs {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string[]]$Plugin,
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    # make sure any account passed in is actually associated with the current server
    # or if no account was specified, that there's a current account.
    if (-not $Account) {
        if (-not ($Account = Get-PAAccount)) {
            throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
        }
    } else {
        if ($Account.id -notin (Get-PAAccount -List).id) {
            throw "Specified account id $($Account.id) was not found in the current server's account list."
        }
    }

    # build the path to the plugin data file and import it
    $pDataFile = Join-Path (Join-Path (Get-DirFolder) $Account.id) 'plugindata.xml'
    if (Test-Path -Path $pDataFile -PathType Leaf) {
        # import the existing file
        Write-Debug "Loading saved plugin data"
        $pData = Import-CliXml $pDataFile
    } else {
        # return early with an empty hashtable because nothing was saved
        return @{}
    }

    # If one or more plugins are specified, we want to filter out args from
    # the saved set that are unrelated to the specified ones.
    # NOTE: There is no checking for ambiguous parameter sets here.
    # We're going to assume Export-PluginArgs has already made sure there are none saved.
    if ($Plugin) {
        $uniquePlugins = @($Plugin) | Sort-Object -Unique
        if ($uniquePlugins.Count -gt 0) {
            # Get the list of non-common param names from the specified plugins
            $paramNames = @()
            $ignoreParams = @('RecordName','TxtValue','Url','Body') + [Management.Automation.PSCmdlet]::CommonParameters +
                [Management.Automation.PSCmdlet]::OptionalCommonParameters

            $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'Plugins'

            foreach ($p in $uniquePlugins) {

                # validate the plugin and get its challenge type
                $chalType = Get-PluginType $p

                # dot source the plugin file
                . (Join-Path $pluginDir "$p.ps1")

                # grab a reference to the appropriate Add command
                if ('dns-01' -eq $chalType) {
                    $cmd = Get-Command Add-DnsTxt
                } else {
                    $cmd = Get-Command Add-HttpChallenge
                }

                # add the non-common names to the list
                $paramNames += $cmd.Parameters.Keys | Where-Object {
                    ($_ -notin $ignoreParams) -and
                    ($true -notin $cmd.Parameters[$_].Attributes.ValueFromRemainingArguments)
                }
            }

            # now remove any saved params that don't match our list
            foreach ($paramName in @($pData.Keys)) {
                if ($paramName -notin $paramNames) {
                    $pData.Remove($paramName)
                }
            }
        }
    }

    return $pData
}
