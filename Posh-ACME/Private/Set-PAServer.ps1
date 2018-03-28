function Set-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnown='LE_STAGE',
        [Parameter(Mandatory,ParameterSetName='Custom')]
        [string]$Custom
    )

    # grab the appropriate directory URI
    if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
        $DirUri = $script:WellKnownDirs[$WellKnown]
    } else {
        $DirUri = $Custom
    }

    # tweak it so we can create a folder from it
    $DirFolder = $DirUri.Replace('https://','').Replace(':','_')
    $DirFolder = Join-Path $script:ConfigRoot $DirFolder.Substring(0,$DirFolder.IndexOf('/'))

    # create the folder if it doesn't exist
    if (!(Test-Path $DirFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $DirFolder -Force | Out-Null
    }

    # save it to memory, current-server.txt, and the folder's dir.txt
    $script:CurrentDir = $DirUri
    $DirUri | Out-File (Join-Path $script:ConfigRoot 'current-server.txt') -Force
    $DirUri | Out-File (Join-Path $DirFolder 'dir.txt') -Force

    # refresh the directory in memory
    Update-PAServer $DirUri

}
