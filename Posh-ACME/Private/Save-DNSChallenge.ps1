function Save-DNSChallenge {
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
    $saveCommand = "Save-DnsChallenge$Plugin"
    if (!(Get-Command $saveCommand -ErrorAction SilentlyContinue)) {
        throw "Expected plugin command $saveCommand not found."
    }

    # call the function with the required parameters and splatting the rest
    &$saveCommand @PluginArgs
}