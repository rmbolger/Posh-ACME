function Import-PluginDetail {
    [CmdletBinding()]
    param()

    # Cache all of the plugin details into a module variable that other
    # things can reference for easy access:
    # - Name
    # - ChallengeType
    # - Filesystem Path

    # initialize the module variable
    $script:Plugins = @{}

    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'Plugins'
    Write-Debug "Loading plugin details from $pluginDir"

    $allPluginFiles = Get-ChildItem (Join-Path $pluginDir '*.ps1') -Exclude '_Example*'

    $functionNames = @(
        'Function:Get-CurrentPluginType'
        'Function:Add-DnsTxt'
        'Function:Remove-DnsTxt'
        'Function:Save-DnsTxt'
        'Function:Add-HttpChallenge'
        'Function:Remove-HttpChallenge'
        'Function:Save-HttpChallenge'
    )

    foreach ($pFile in $allPluginFiles) {

        # remove references to previous plugin functions so we can validate
        # this one properly
        Remove-Item $functionNames -EA Ignore

        # dot source it
        . $pFile.FullName

        $pName = $pFile.BaseName

        # make sure it has the type function
        if (-not (Get-Command 'Get-CurrentPluginType' -EA Ignore)) {
            Write-Warning "$pName plugin is missing Get-CurrentPluginType function. Will not use."
            continue
        }

        # make sure it has type specific functions
        $chalType = Get-CurrentPluginType
        if ('dns-01' -eq $chalType) {
            if (-not (Get-Command 'Add-DnsTxt' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Add-DnsTxt function. Will not use."
                continue
            }
            if (-not (Get-Command 'Remove-DnsTxt' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Remove-DnsTxt function. Will not use."
                continue
            }
            if (-not (Get-Command 'Save-DnsTxt' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Save-DnsTxt function. Will not use."
                continue
            }
        } elseif ('http-01' -eq $chalType) {
            if (-not (Get-Command 'Add-HttpChallenge' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Add-HttpChallenge function. Will not use."
                continue
            }
            if (-not (Get-Command 'Remove-HttpChallenge' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Remove-HttpChallenge function. Will not use."
                continue
            }
            if (-not (Get-Command 'Save-HttpChallenge' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Save-HttpChallenge function. Will not use."
                continue
            }
        } else {
            Write-Warning "$pName plugin sent unrecognized challenge type. Will not use."
            continue
        }

        # add it to the module variable
        $script:Plugins.$pName = [pscustomobject]@{
            PSTypeName = 'PoshACME.PAPluginDetail'
            Name = $pName
            ChallengeType = $chalType
            Path = $pFile.FullName
        }

    }

}
