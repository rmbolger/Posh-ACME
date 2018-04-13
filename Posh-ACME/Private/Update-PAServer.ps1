function Update-PAServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [switch]$NonceOnly
    )

    # grab the directory url from explicit parameters or the current memory copy
    if (!$DirectoryUrl) {
        if (!$script:Dir -or !$script:Dir.location) {
            throw "No ACME server configured. Run Set-PAServer or specify a DirectoryUrl."
        }
        $DirectoryUrl = $script:Dir.location
        $UpdatingCurrent = $true
    } else {
        # even if they specified the directory url explicitly, we may still be updating the
        # "current" server. So figure that out and set a flag for later.
        if ($script:Dir -and $script:Dir.location -and $script:Dir.location -eq $DirectoryUrl) {
            $UpdatingCurrent = $true
        } else {
            $UpdatingCurrent = $false
        }
    }

    # determine the directory folder/file
    $dirFolder = $DirectoryUrl.Replace('https://','').Replace(':','_')
    $dirFolder = Join-Path $script:ConfigRoot $dirFolder.Substring(0,$dirFolder.IndexOf('/'))
    $dirFile = Join-Path $dirFolder 'dir.json'

    # Full refresh
    if (!$NonceOnly -or !(Test-Path $dirFile -PathType Leaf)) {

        # If the caller asked for a NonceOnly refresh but there's no existing dir.json,
        # we'll just do a full refresh with a warning.
        if ($NonceOnly) {
            Write-Warning "Performing full update instead of NonceOnly because existing server details missing."
        }

        # make the request
        Write-Verbose "Updating directory info from $DirectoryUrl"
        try {
            $response = Invoke-WebRequest $DirectoryUrl -Verbose:$false -ErrorAction Stop
        } catch { throw }
        $dirObj = $response.Content | ConvertFrom-Json

        # process the response
        if ($dirObj -is [pscustomobject] -and 'newAccount' -in $dirObj.PSObject.Properties.name) {

            # create the directory folder if necessary
            if (!(Test-Path $dirFolder -PathType Container)) {
                New-Item -ItemType Directory -Path $dirFolder -Force | Out-Null
            }

            # add location, nonce, and type to the returned directory object
            $dirObj | Add-Member -MemberType NoteProperty -Name 'location' -value $DirectoryUrl
            $dirObj | Add-Member -MemberType NoteProperty -Name 'nonce' -value $null
            $dirObj.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

            # update the nonce value
            if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
                $dirObj.nonce = $response.Headers.$script:HEADER_NONCE
            } else {
                $dirObj.nonce = Get-Nonce $dirObj.newNonce
            }

            # save to disk
            Write-Verbose "Saving PAServer to disk"
            $dirObj | ConvertTo-Json | Out-File $dirFile -Force

            # overwrite the in-memory copy if we're actually updating the current one
            if ($UpdatingCurrent) { $script:Dir = $dirObj }

        } else {
            Write-Verbose ($dirObj | ConvertTo-Json)
            throw "Unexpected ACME response querying directory. Check with -Verbose."
        }

    # Nonce only refresh
    } else {

        # grab a reference to the object we'll be updating
        if ($UpdatingCurrent) {
            Write-Verbose "Nonce Before: $($script:Dir.nonce)"
            $dirObj = $script:Dir
        } else {
            $dirObj = Get-PAServer $DirectoryUrl
        }

        # update the nonce value
        $dirObj.nonce = Get-Nonce $dirObj.newNonce

        # save to disk
        Write-Verbose "Saving PAServer to disk"
        $dirObj | ConvertTo-Json | Out-File $dirFile -Force

        if ($UpdatingCurrent) { Write-Verbose "Nonce After: $($script:Dir.nonce)" }
    }

}
