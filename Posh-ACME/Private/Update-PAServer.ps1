function Update-PAServer {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # make sure we have a server configured
    if ([string]::IsNullOrWhiteSpace($script:DirUrl)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # set the DirFolder
    $dirFolder = $script:DirUrl.Replace('https://','').Replace(':','_')
    $dirFolder = Join-Path $script:ConfigRoot $dirFolder.Substring(0,$dirFolder.IndexOf('/'))
    $script:DirFolder = $dirFolder
    if (!(Test-Path $script:DirFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $script:DirFolder -Force | Out-Null
    }

    Write-Verbose "Updating directory info from $script:DirUrl"
    try {
        $response = Invoke-WebRequest $script:DirUrl -Verbose:$false -ErrorAction Stop
    } catch { throw }
    $dirObj = $response.Content | ConvertFrom-Json

    if ($dirObj -is [pscustomobject] -and 'newAccount' -in $dirObj.PSObject.Properties.name) {

        # add the location and type to the returned directory object
        $dirObj | Add-Member -MemberType NoteProperty -Name 'location' -value $script:DirUrl
        $dirObj.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

        # save to memory
        $script:Dir = $dirObj

        # save to disk
        $script:Dir | ConvertTo-Json | Out-File (Join-Path $script:DirFolder 'dir.json') -Force

        # grab the next nonce
        if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
            $script:NextNonce = $response.Headers.$script:HEADER_NONCE
        } else {
            $Script:NextNonce = Get-Nonce $script:DirUrl
        }

    } else {
        Write-Verbose ($dirObj | ConvertTo-Json)
        throw "Unexpected ACME response querying directory. Check with -Verbose."
    }
}
