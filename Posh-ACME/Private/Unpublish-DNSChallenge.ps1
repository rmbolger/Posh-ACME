function Unpublish-DNSChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [string]$Plugin,
        [Parameter(Position=2)]
        [hashtable]$PluginArgs
    )

    $recordName = "_acme_challenge.$Domain"

    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'
    $pluginFile = Join-Path $pluginDir "$Plugin.ps1"

    # dot source the plugin file
    . $pluginFile

    # check for the command that should exist now based on plugin name
    $delCommand = "Remove-DnsChallenge$Plugin"
    if (!(Get-Command $delCommand -ErrorAction SilentlyContinue)) {
        throw "Expected plugin command $delCommand not found."
    }

    # call the function with the required parameters and splatting the rest
    &$delCommand $recordName @PluginArgs

}