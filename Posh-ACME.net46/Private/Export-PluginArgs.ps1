function Export-PluginArgs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$PluginArgs,
        [Parameter(Mandatory,Position=1)]
        [string[]]$DnsPlugin,
        [PSTypeName('PoshACME.PAAccount')]$Account
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

    # build the path to the existing plugin data file and import it
    $pDataFile = Join-Path (Join-Path (Get-DirFolder) $Account.id) 'plugindata.xml'
    if (Test-Path -Path $pDataFile -PathType Leaf) {
        # import the existing file
        Write-Debug "Loading saved plugin data"
        $pData = Import-CliXml $pDataFile -EA Ignore
    }
    if ($null -eq $pData -or $pData -isnot [hashtable]) {
        # The existing file either didn't exist or was corrupt.
        # Just initialize the old data to an empty hashtable.
        $pData = @{}
    }

    # define the set of parameter names to ignore
    $ignoreParams = @('RecordName','TxtValue') + [Management.Automation.PSCmdlet]::CommonParameters +
        [Management.Automation.PSCmdlet]::OptionalCommonParameters

    # $DnsPlugin will most often come with duplicates after being called from Submit-ChallengeValidation
    # So grab just the unique set.
    $uniquePlugins = $DnsPlugin | Sort-Object -Unique

    # loop through the unique set of plugins
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

        # grab the set of non-common param names
        $paramNames = $cmd.Parameters.Keys | Where-Object {
            ($_ -notin $ignoreParams) -and
            ($true -notin $cmd.Parameters[$_].Attributes.ValueFromRemainingArguments)
        }

        $hasNewArgs = $(foreach ($key in $PluginArgs.Keys) { if ($key -in $paramNames) { $true; break; } }) -eq $true
        if ($hasNewArgs) {
            Write-Debug "New args for $plugin found."

            # check for and remove old args
            foreach ($key in @($pData.Keys)) {
                if ($key -in $paramNames) {
                    Write-Debug "Removing old value for $key"
                    $pData.Remove($key)
                }
            }
        } else {
            Write-Debug "No new args for $plugin"
        }
    }

    # merge the new args with old data
    foreach ($key in $PluginArgs.Keys) {
        Write-Debug "Adding new value for $key"
        $pData.$key = $PluginArgs.$key
    }

    # export the merged object
    $pData | Export-Clixml $pDataFile -Force -EA Stop
}
