function Get-PAServer {
    [CmdletBinding(DefaultParameterSetName='Specific')]
    [OutputType('PoshACME.PAServer')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ParameterSetName='Specific',ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [switch]$Refresh,
        [Parameter(ParameterSetName='Specific')]
        [switch]$Quiet
    )

    Process {

        # List mode
        if ('List' -eq $PSCmdlet.ParameterSetName) {

            # update from the server first if requested
            if ($Refresh) {
                Get-PAServer -List | Set-PAServer -NoSwitch
            }

            # read the contents of each server's dir.json
            Write-Debug "Loading PAServer list from disk"
            Get-ChildItem (Join-Path (Get-ConfigRoot) '\*\dir.json') | ForEach-Object {

                # parse the json
                $dirObj = $_ | Get-Content -Raw | ConvertFrom-Json

                # insert the type name so it displays properly
                $dirObj.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

                # add the friendly name and folder
                $dirObj | Add-Member 'Name' $_.Directory.Name -Force
                $dirObj | Add-Member 'Folder' $_.Directory.FullName -Force

                # send the result to the pipeline
                Write-Output $dirObj
            }

        # Specific mode
        } else {

            if ($DirectoryUrl) {
                # DirectoryUrl gets priority

                # convert WellKnown names to their associated Url
                if ($DirectoryUrl -notlike 'https://*') {
                    $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
                }

                $dir = Get-PAServer -List | Where-Object { $_.location -eq $DirectoryUrl }

                if (-not $dir -and -not $Quiet) {
                    Write-Warning "Unable to find cached PAServer info for $DirectoryUrl. Try using Set-PAServer first."
                }
            }
            elseif ($Name) {

                # get the server by Name
                $dir = Get-PAServer -List | Where-Object { $_.Name -eq $Name }

                if (-not $dir -and -not $Quiet) {
                    Write-Warning "Unable to find cached PAServer info for $Name. Try using Set-PAServer first."
                }

            }
            # Use the current one
            else {
                $dir = $script:Dir
            }

            if ($dir -and $Refresh) {

                # update and the server then recurse to return the updated data
                Set-PAServer -DirectoryUrl $dir.location -NoSwitch
                Get-PAServer -DirectoryUrl $dir.location

            } else {
                # return whatever we've got
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
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2), LE_STAGE (LetsEncrypt Staging v2), BUYPASS_PROD (BuyPass.com Production), and BUYPASS_TEST (BuyPass.com Testing).

    .PARAMETER Name
        The friendly name of the ACME server. The parameter is ignored if DirectoryUrl is specified.

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
