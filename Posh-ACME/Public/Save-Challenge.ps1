function Save-Challenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string]$Plugin,
        [Parameter(Position=1)]
        [hashtable]$PluginArgs
    )

    # dot source the plugin file
    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'Plugins'
    . (Join-Path $pluginDir "$Plugin.ps1")

    # get the validation type
    if (-not (Get-Command 'Get-CurrentPluginType' -EA Ignore)) {
        throw 'Plugin is missing Get-CurrentPluginType function. Unable to continue.'
    }
    if (($chalType = Get-CurrentPluginType) -notin 'dns-01','http-01') {
        throw 'Plugin sent unrecognized challenge type.'
    }

    # do stuff appropriate for the challenge type
    if ('dns-01' -eq $chalType) {

        # check for the Save command that should exist now from the plugin
        if (-not (Get-Command 'Save-DnsTxt' -EA Ignore)) {
            throw "Plugin is missing Save-DnsTxt function. Unable to continue."
        }

        Write-Debug "Calling $Plugin plugin to save"

        # call the function with the required parameters and splatting the rest
        Save-DnsTxt @PluginArgs

    } else { # http-01 is the only other challenge type we support at the moment

        # check for the Save command that should exist now from the plugin
        if (-not (Get-Command 'Save-HttpChallenge' -EA Ignore)) {
            throw "Plugin is missing Save-HttpChallenge function. Unable to continue."
        }

        Write-Debug "Calling $Plugin plugin to save"

        # call the function with the required parameters and splatting the rest
        Save-HttpChallenge @PluginArgs

    }



    <#
    .SYNOPSIS
        Commit changes made by Publish-Challenge or Unpublish-Challenge.

    .DESCRIPTION
        Some validation plugins require a finalization step after the Publish or Unpublish functionality to commit and make the changes live. This function should be called once after running all of the Publish-Challenge or Unpublish-Challenge commands.

        For plugins that don't require a commit step, this function may still be run without causing an error, but does nothing.

    .PARAMETER Plugin
        The name of the validation plugin to use. Use Get-PAPlugin to display a list of available plugins.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified plugin. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .EXAMPLE
        Save-Challenge Manual @{}

        Commit changes using the Manual DNS plugin that requires no plugin arguments.

    .EXAMPLE
        Save-Challenge MyPlugin @{Param1='asdf';Param2=1234}

        Commit changes for a set of challenges using a fictitious plugin and arguments.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Publish-Challenge

    .LINK
        Unpublish-Challenge

    .LINK
        Get-PAPlugin

    #>
}
