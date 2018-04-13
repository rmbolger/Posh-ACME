function Set-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl
    )

    # convert WellKnown names to their associated Url
    if ($DirectoryUrl -notlike 'https://*') {
        $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
    }

    # make sure we're actually changing servers before doing anything else
    if (!$script:Dir -or !$script:Dir.location -or $DirectoryUrl -ne $script:Dir.location) {

        # reset child object references
        $script:Acct = $null
        $script:AcctFolder = $null
        $script:Order = $null
        $script:OrderFolder = $null

        Update-PAServer $DirectoryUrl

        # save to disk
        $DirectoryUrl | Out-File (Join-Path $script:ConfigRoot 'current-server.txt') -Force

        # reload config from disk
        Import-PAConfig
    }





    <#
    .SYNOPSIS
        Set the current ACME server.

    .DESCRIPTION
        Use this function to switch between ACME servers. Switching also refreshes the cached data for the new server.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2).

    .EXAMPLE
        Set-PAServer LE_PROD

        Switch to the LetsEncrypt production server using the short name.

    .EXAMPLE
        Set-PAServer -DirectoryUrl https://myacme.example.com/directory

        Switch to the specified ACME server using the directory URL.

    .EXAMPLE
        (Get-PAServer -List)[0] | Set-PAServer

        Switch to the first ACME server returned by "Get-PAServer -List"

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAServer

    #>
}
