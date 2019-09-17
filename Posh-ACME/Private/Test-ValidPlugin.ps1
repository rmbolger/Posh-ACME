function Test-ValidPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$PluginName,
        [switch]$ThrowOnFail
    )

    $PluginName | ForEach-Object {
        # getting the challenge type will also do some validation on the
        # plugin internals and throw if it fails those tests.
        try {
            Get-PluginType $_ | Out-Null
        } catch {
            if ($ThrowOnFail) { throw }
            else { return $false }
        }
    }

    return $true
}
