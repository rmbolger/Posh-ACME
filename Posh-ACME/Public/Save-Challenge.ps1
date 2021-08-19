function Save-Challenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string]$Plugin,
        [Parameter(Position=1)]
        [hashtable]$PluginArgs
    )

    Write-Verbose "Saving changes for $Plugin plugin"

    # dot source the plugin file
    $pluginDetail = $script:Plugins.$Plugin
    . $pluginDetail.Path

    # All plugins in $script:Plugins should have been validated during module
    # load. So we're not going to do much plugin-specific validation here.

    # do stuff appropriate for the challenge type
    if ('dns-01' -eq $pluginDetail.ChallengeType) {

        Write-Debug "Calling $Plugin plugin to save"

        # call the function with the required parameters and splatting the rest
        Save-DnsTxt @PluginArgs

    } else { # http-01 is the only other challenge type we support at the moment

        Write-Debug "Calling $Plugin plugin to save"

        # call the function with the required parameters and splatting the rest
        Save-HttpChallenge @PluginArgs

    }
}
