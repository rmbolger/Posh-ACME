function Set-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirUrl='LE_STAGE'
    )

    # convert non-WellKnown names to their associated Url
    if ($DirUrl -notlike 'https://*') {
        $DirUrl = $script:WellKnownDirs.$DirUrl
    }

    # reset child object references if we're actually changing servers
    if ($DirUrl -ne $script:DirUrl) {
        $script:Acct = $null
        $script:AcctFolder = $null
        $script:Order = $null
        $script:OrderFolder = $null
    }

    # save to disk
    $DirUrl | Out-File (Join-Path $script:ConfigRoot 'current-server.txt') -Force

    # reload config from disk
    Import-PAConfig
}
