function Test-ValidPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$PluginName,
        [switch]$ThrowOnFail
    )

    foreach ($name in $PluginName) {

        if (-not ($script:Plugins.$name)) {

            if ($ThrowOnFail) {
                throw "$name plugin not found or was invalid."
            } else {
                return $false
            }

        }
    }

    return $true
}
