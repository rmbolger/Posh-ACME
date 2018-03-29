function Set-PAServer {
    [CmdletBinding(DefaultParameterSetName='WellKnown')]
    param(
        [Parameter(ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnown='LE_STAGE',
        [Parameter(Mandatory,ParameterSetName='Custom')]
        [string]$Custom
    )

    # grab the appropriate directory URI
    if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
        $DirUrl = $script:WellKnownDirs[$WellKnown]
    } else {
        $DirUrl = $Custom
    }

    # create the folder if it doesn't exist
    $DirFolder = Convert-DirToFolder $DirUrl
    if (!(Test-Path $DirFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $DirFolder -Force | Out-Null
    }

    # save to disk
    $DirUrl | Out-File (Join-Path $script:ConfigRoot 'current-server.txt') -Force
    $DirUrl | Out-File (Join-Path $DirFolder 'dir.txt') -Force

    # reload config from disk
    Import-PAConfig
}
