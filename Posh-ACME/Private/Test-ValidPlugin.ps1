function Test-ValidPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$PluginName,
        [switch]$ThrowOnFail
    )

    $PluginName | ForEach-Object {

        if (-not ($script:Plugins.$_)) {

            if ($ThrowOnFail) {
                throw "$PluginName plugin not found or was invalid."
            } else {
                return $false
            }

        }
    }

    return $true
}
