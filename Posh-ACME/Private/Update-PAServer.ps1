function Update-PAServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [switch]$SkipCertificateCheck,
        [switch]$DisableTelemetry,
        [switch]$NoRefresh
    )

    Process {

        # grab the directory url from explicit parameters or the current memory copy
        if (-not $DirectoryUrl) {
            if (-not $script:Dir) {
                throw "No ACME server configured. Run Set-PAServer or specify a DirectoryUrl."
            }
            $DirectoryUrl = $script:Dir.location
        }

        # determine the directory folder/file
        $dirFolder = ConvertTo-DirFolder $DirectoryUrl
        $dirFile = Join-Path $dirFolder 'dir.json'

        if (Test-Path $dirFile -PathType Leaf) {
            # grab the existing copy
            $oldDir = Get-Content $dirFile -Raw | ConvertFrom-Json
            $oldDir.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')
        }

        if ($NoRefresh -and $oldDir) {
            # This is a local settings update only.
            $dirObj = $oldDir

            # Update the local settings that are changeable
            if ('SkipCertificateCheck' -in $PSBoundParameters.Keys) {
                $dirObj | Add-Member 'SkipCertificateCheck' $SkipCertificateCheck.IsPresent -Force
            }
            if ('DisableTelemetry' -in $PSBoundParameters.Keys) {
                $dirObj | Add-Member 'DisableTelemetry' $DisableTelemetry.IsPresent -Force
            }
        }
        else {
            # Query the ACME server for any updates

            # Warn if they asked not to refresh but there's no cached object
            if ($NoRefresh) {
                Write-Warning "Performing full server update because cached server details are missing."
            }

            # make the request
            Write-Debug "Updating directory info from $DirectoryUrl"
            try {
                $iwrSplat = @{
                    Uri = $DirectoryUrl
                    UserAgent = $script:USER_AGENT
                    ErrorAction = 'Stop'
                    Verbose = $false
                }
                $response = Invoke-WebRequest @iwrSplat @script:UseBasic
            } catch {
                Write-Error -Exception $_.Exception
                return
            }
            try {
                $dirObj = $response.Content | ConvertFrom-Json
            } catch {
                Write-Debug "ACME Response: `n$($response.Content)"
                Write-Error "ACME response from $DirectoryUrl was not valid JSON. Details are in Debug output."
                return
            }

            # create the directory folder if necessary
            if (-not (Test-Path $dirFolder -PathType Container)) {
                New-Item -ItemType Directory -Path $dirFolder -Force -EA Stop | Out-Null
            }

            # add additional metadata to the returned directory object
            $dirObj | Add-Member -NotePropertyMembers @{
                location = $DirectoryUrl
                nonce = $null
            }
            $dirObj.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

            # set preference values to the old values unless they were explicitly specified
            if ($oldDir -and $oldDir.SkipCertificateCheck -and 'SkipCertificateCheck' -notin $PSBoundParameters.Keys) {
                $dirObj | Add-Member 'SkipCertificateCheck' $oldDir.SkipCertificateCheck
            } else {
                $dirObj | Add-Member 'SkipCertificateCheck' $SkipCertificateCheck.IsPresent
            }
            if ($oldDir -and $oldDir.DisableTelemetry -and 'DisableTelemetry' -notin $PSBoundParameters.Keys) {
                $dirObj | Add-Member 'DisableTelemetry' $oldDir.DisableTelemetry
            } else {
                $dirObj | Add-Member 'DisableTelemetry' $DisableTelemetry.IsPresent
            }

            # update the nonce value
            if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
                $dirObj.nonce = $response.Headers[$script:HEADER_NONCE] | Select-Object -First 1
            } else {
                $dirObj.nonce = Get-Nonce $dirObj.newNonce
            }

        }

        # save to disk
        Write-Debug "Saving PAServer to disk"
        $dirObj | ConvertTo-Json -Depth 5 | Out-File $dirFile -Force -EA Stop

        # overwrite the in-memory copy if we're actually updating the current one
        if ($script:Dir -and $script:Dir.location -eq $dirObj.location) {
            $script:Dir = $dirObj
        }

    }

}
