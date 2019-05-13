function Import-PluginArgs {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string[]]$DnsPlugin,
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
    # the saved set that are unrelated to thespecified ones.
    # NOTE: There is no checking for ambiguous parameter sets here.
    # We're going to assume Export-PluginArgs has already made sure there are none saved.
    if ($DnsPlugin) {
        $uniquePlugins = @($DnsPlugin) | Sort-Object -Unique
        if ($uniquePlugins.Count -gt 0) {
            # Get the list of non-common param names from the specified plugins
            $paramNames = @()
            $ignoreParams = @('RecordName','TxtValue') + [Management.Automation.PSCmdlet]::CommonParameters +
                [Management.Automation.PSCmdlet]::OptionalCommonParameters

            foreach ($plugin in $uniquePlugins) {
                # dot source the plugin file
                try {
                    . (Join-Path $PSScriptRoot "..\DnsPlugins\$plugin.ps1")
                } catch { throw }

                # check for the add command that should exist now
                $addCmdName = "Add-DnsTxt$Plugin"
                if (-not ($cmd = Get-Command $addCmdName -ErrorAction Ignore)) {
                    throw "Expected plugin command $addCmdName not found."
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
