function Get-PAServer {
    [CmdletBinding()]
    [OutputType('PoshACME.PAServer')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [switch]$Refresh,
        [switch]$Quiet
    )

    Process {

        # List mode
        if ('List' -eq $PSCmdlet.ParameterSetName) {

            # update from the server first if requested
            if ($Refresh) {
                Get-PAServer -List | Update-PAServer
            }

            # read the contents of each server's dir.json
            Write-Debug "Loading PAServer list from disk"
            $rawFiles = Get-ChildItem (Join-Path (Get-ConfigRoot) '\*\dir.json') | Get-Content -Raw
            $rawFiles | ConvertFrom-Json | Sort-Object location | ForEach-Object {

                    # insert the type name so it displays properly
                    $_.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

                    # send the result to the pipeline
                    Write-Output $_
            }

        # Specific mode
        } else {

            if ($DirectoryUrl) {

                # convert WellKnown names to their associated Url
                if ($DirectoryUrl -notlike 'https://*') {
                    $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
                }

                # build the path to dir.json
                $dirFolder = ConvertTo-DirFolder $DirectoryUrl
                $dirFile = Join-Path $dirFolder 'dir.json'

                # check if it exists
                if (Test-Path $dirFile -PathType Leaf) {
                    Write-Debug "Loading PAServer from disk"
                    $dir = Get-Content $dirFile -Raw | ConvertFrom-Json
                    $dir.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')
                } else {
                    if (-not $Quiet) {
                        Write-Warning "Unable to find cached PAServer info for $DirectoryUrl. Try using Set-PAServer first."
                    }
                    return $null
                }

            } else {
                # just use the current one
                $dir = $script:Dir
            }

            if ($dir -and $Refresh) {

                # update and then recurse to return the updated data
                Update-PAServer $dir.location
                return (Get-PAServer $dir.location)

            } else {

                # just return whatever we've got
                return $dir
            }
        }
    }





    <#
    .SYNOPSIS
        Get ACME server details.

    .DESCRIPTION
        The primary use for this function is checking which ACME server is currently configured. New Account and Cert requests will be directed to this server. It may also be used to refresh server details and list additional servers that have previously been used.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2).

    .PARAMETER List
        If specified, the details for all previously used servers will be returned.

    .PARAMETER Refresh
        If specified, any server details returned will be freshly queried from the ACME server. Otherwise, cached details will be returned.

    .PARAMETER Quiet
        If specified, no warning will be thrown if a specified server is not found.

    .EXAMPLE
        Get-PAServer

        Get cached ACME server details for the currently selected server.

    .EXAMPLE
        Get-PAServer -DirectoryUrl LE_PROD

        Get cached LetsEncrypt production server details using the short name.

    .EXAMPLE
        Get-PAServer -List

        Get all cached ACME server details.

    .EXAMPLE
        Get-PAServer -DirectoryUrl https://myacme.example.com/directory

        Get cached ACME server details for the specified directory URL.

    .EXAMPLE
        Get-PAServer -Refresh

        Get fresh ACME server details for the currently selected server.

    .EXAMPLE
        Get-PAServer -List -Refresh

        Get fresh ACME server details for all previously used servers.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Set-PAServer

    #>
}
