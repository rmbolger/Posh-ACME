function Save-DnsChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Plugin,
        [Parameter(Position=1)]
        [hashtable]$PluginArgs
    )

    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'
    $pluginFile = Join-Path $pluginDir "$Plugin.ps1"

    # dot source the plugin file
    . $pluginFile

    # check for the command that should exist now based on plugin name
    $saveCommand = "Save-DnsTxt$Plugin"
    if (!(Get-Command $saveCommand -ErrorAction SilentlyContinue)) {
        throw "Expected plugin command $saveCommand not found."
    }

    # call the function with the required parameters and splatting the rest
    &$saveCommand @PluginArgs





    <#
    .SYNOPSIS
        Commit previously published DNS challenges to the DNS server.

    .DESCRIPTION
        Some DNS plugins don't make published DNS challenges live right away and require a save or commit step. This function should be called once after running all of the Publish-DnsChallenge commands.

        For DNS plugins that don't require a commit step, this function can still be run but does nothing.

    .PARAMETER Plugin
        The name of the DNS plugin to use. Use Get-DnsPlugins to display a list of available plugins.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified DnsPlugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .EXAMPLE
        Save-DnsChallenge Manual @{}

        Commit changes using the Manual DNS plugin that requires no plugin arguments.

    .EXAMPLE
        Save-DnsChallenge Flurbog @{FBServer='127.0.0.1';FBToken='abc123'}

        Commit changes using the Flurbog DNS plugin that requires FBServer and FBToken arguments.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Publish-DnsChallenge

    .LINK
        Unpublish-DnsChallenge

    .LINK
        Get-DnsPlugins

    .LINK
        Get-DnsPluginHelp

    #>
}
