function Get-PluginType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [string]$Plugin
    )

    # While this function primarily exists to get the challenge type associated
    # with a particular plugin. We're also going to use it to do some runtime
    # validation of a given plugin as well. But we only want to have to do that
    # once per plugin per session. So we're going to cache the results.

    Process {
        # return the cached value if it exists
        if ($script:PluginTypes.ContainsKey($Plugin)) {
            return $script:PluginTypes[$Plugin]
        }

        # dot source the plugin so we can check what type it is
        $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'Plugins'
        $pluginFile = Join-Path $pluginDir "$Plugin.ps1"
        if (-not (Test-Path $pluginFile -PathType Leaf)) {
            throw "$Plugin plugin file not found at $pluginFile."
        }
        . $pluginFile

        # make sure it has the type function
        if (-not (Get-Command 'Get-CurrentPluginType' -EA Ignore)) {
            throw "$Plugin plugin is missing Get-CurrentPluginType function."
        }

        # make sure it has type specific functions
        $chalType = Get-CurrentPluginType
        if ('dns-01' -eq $chalType) {
            if (-not (Get-Command 'Add-DnsTxt' -EA Ignore)) {
                throw "$Plugin plugin is missing Add-DnsTxt function."
            }
            if (-not (Get-Command 'Remove-DnsTxt' -EA Ignore)) {
                throw "$Plugin plugin is missing Remove-DnsTxt function."
            }
            if (-not (Get-Command 'Save-DnsTxt' -EA Ignore)) {
                throw "$Plugin plugin is missing Save-DnsTxt function."
            }
        } elseif ('http-01' -eq $chalType) {
            if (-not (Get-Command 'Add-HttpChallenge' -EA Ignore)) {
                throw "$Plugin plugin is missing Add-HttpChallenge function."
            }
            if (-not (Get-Command 'Remove-HttpChallenge' -EA Ignore)) {
                throw "$Plugin plugin is missing Remove-HttpChallenge function."
            }
            if (-not (Get-Command 'Save-HttpChallenge' -EA Ignore)) {
                throw "$Plugin plugin is missing Save-HttpChallenge function."
            }
        } else {
            throw "$Plugin plugin sent unrecognized challenge type."
        }

        # cache and return the type
        $script:PluginTypes[$Plugin] = $chalType
        return $chalType
    }
}
