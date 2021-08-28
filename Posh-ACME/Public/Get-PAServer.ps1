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
            Get-ChildItem (Join-Path (Get-ConfigRoot) '\*\dir.json') |
                Sort-Object {$_.Directory.Name} |
                ForEach-Object {

                # parse the json
                $dirObj = $_ | Get-Content -Raw | ConvertFrom-Json

                # insert the type name so it displays properly
                $dirObj.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

                # add the name and folder
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
}
