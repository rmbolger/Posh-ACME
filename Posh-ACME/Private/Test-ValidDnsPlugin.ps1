function Test-ValidDnsPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$PluginName,
        [switch]$ThrowOnFail
    )

    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'

    $PluginName | ForEach-Object {
        # check for a file with the matching name in the DnsPlugins folder
        $pluginFile = Join-Path $pluginDir "$_.ps1"
        if (!(Test-Path $pluginFile)) {
            if ($ThrowOnFail) {
                throw "$_ plugin not found at $pluginFile"
            } else {
                return $false
            }
        }
    }

    return $true
}