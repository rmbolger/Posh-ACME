function Set-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$NewName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$SkipCertificateCheck,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$DisableTelemetry,
        [switch]$NoRefresh,
        [switch]$NoSwitch
    )

    Process {

        $curDir = Get-PAServer

        # make sure we have DirectoryUrl, Name, or an existing active server
        if (-not ($DirectoryUrl -or $Name -or $curDir)) {
            try { throw "No DirectoryUrl or Name specified and no active server. Please specify a DirectoryUrl." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # try to find an existing server that matches DirectoryUrl/Name
        if ($DirectoryUrl) {

            # convert WellKnown names to their associated Url
            if ($DirectoryUrl -notlike 'https://*') {
                Write-Debug "$DirectoryUrl converted to $($script:WellKnownDirs.$DirectoryUrl)"
                $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
            }

            # ignore the Name parameter when DirectoryUrl is specified
            $newDir = Get-PAServer -DirectoryUrl $DirectoryUrl -Quiet

            # if a cached server doesn't exist, create the basics of a new one
            # that we'll fully populate later
            if (-not $newDir) {

                if (-not $Name) {
                    # generate a default name using the Host value of the URL
                    $Name = ([uri]$DirectoryUrl).Host
                }

                $newDir = [pscustomobject]@{
                    PSTypeName = 'PoshACME.PAServer'
                    location = $DirectoryUrl
                    Name = $Name
                    Folder = Join-Path (Get-ConfigRoot) $Name
                    DisableTelemetry = $DisableTelemetry.IsPresent
                    SkipCertificateCheck = $SkipCertificateCheck.IsPresent
                    newAccount = $null
                    newOrder = $null
                    newNonce = $null
                    keyChange = $null
                    revokeCert = $null
                    meta = $null
                    nonce = $null
                }
            }
        }
        elseif ($Name) {
            # Try to find a server that matches Name instead, but error if one
            # doesn't exist because we don't want to fall back on the current
            # server in case it's not what the user intended to update.
            $newDir = Get-PAServer -Name $Name -Quiet
            if (-not $newDir) {
                try { throw "No PAServer found with Name '$Name'." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
        else {
            # use the currently active server
            $newDir = $curDir
        }

        # update the cert validation state before we try to refresh
        if ('SkipCertificateCheck' -in $PSBoundParameters.Keys) {
            Set-CertValidation $SkipCertificateCheck.IsPresent
        }

        # refresh the server details if they don't already exist or NoRefresh
        # wasn't specified
        $firstUse = (-not (Test-Path $newDir.Folder -PathType Container))
        if ($firstUse -or -not $NoRefresh) {

            # Warn if they asked not to refresh but there's no cached object
            if ($NoRefresh) {
                Write-Warning "Performing full server update because cached server details are missing."
            }

            # make the request
            Write-Verbose "Updating directory info from $($newDir.location)"
            try {
                $iwrSplat = @{
                    Uri = $newDir.location
                    UserAgent = $script:USER_AGENT
                    ErrorAction = 'Stop'
                    Verbose = $false
                }
                $response = Invoke-WebRequest @iwrSplat @script:UseBasic
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
            try {
                $dirObj = $response.Content | ConvertFrom-Json
            } catch {
                Write-Debug "ACME Response: `n$($response.Content)"
                try { throw "ACME response from $($newDir.location) was not valid JSON. Details are in Debug output." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }

            # create the server folder if necessary
            if ($firstUse) {
                New-Item -ItemType Directory -Path $newDir.Folder -Force -EA Stop | Out-Null
            }

            # update values from the response object
            $newDir.newAccount = $dirObj.newAccount
            $newDir.newOrder   = $dirObj.newOrder
            $newDir.newNonce   = $dirObj.newNonce
            $newDir.keyChange  = $dirObj.keyChange
            $newDir.revokeCert = $dirObj.revokeCert
            $newDir.meta       = $dirObj.meta

            # update the nonce value
            if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
                $newDir.nonce = $response.Headers[$script:HEADER_NONCE] | Select-Object -First 1
            } else {
                $newDir.nonce = Get-Nonce $dirObj.newNonce
            }
        }

        # update switch param details if necessary
        if ($newDir.DisableTelemetry -ne $DisableTelemetry.IsPresent) {
            Write-Debug "Setting DisableTelemetry value to $($DisableTelemetry.IsPresent)"
            $newDir | Add-Member 'DisableTelemetry' $DisableTelemetry.IsPresent -Force
        }
        if ($newDir.SkipCertificateCheck -ne $SkipCertificateCheck.IsPresent) {
            Write-Debug "Setting SkipCertificateCheck value to $($SkipCertificateCheck.IsPresent)"
            $newDir | Add-Member 'SkipCertificateCheck' $SkipCertificateCheck.IsPresent -Force
        }

        # save the object to disk except for the dynamic properties
        Write-Debug "Saving PAServer to disk"
        $dirFile = Join-Path $newDir.Folder 'dir.json'
        $newDir | Select-Object -Exclude Name,Folder | ConvertTo-Json -Depth 5 | Out-File $dirFile -Force -EA Stop

        if (-not $NoSwitch) {
            # set as the new active server
            $newDir.location | Out-File (Join-Path (Get-ConfigRoot) 'current-server.txt') -Force -EA Stop
        }

        # Deal with potential name change
        if ($NewName -and $NewName -ne $newDir.Name) {

            # rename the dir folder
            $newFolder = Join-Path (Get-ConfigRoot) $NewName
            if (Test-Path $newFolder) {
                Write-Error "Failed to rename PAServer $($newDir.Name). The path '$newFolder' already exists."
            } else {
                Write-Debug "Renaming $($newDir.Name) server folder to $newFolder"
                Rename-Item $newDir.Folder $newFolder
            }
        }

        # reload config from disk
        Import-PAConfig -Level 'Server'

        # Show a link to the TOS if this is the server's first use.
        if ($firstUse) {
            Write-Host "Please review the Terms of Service here: $($script:Dir.meta.termsOfService)"
        }
    }


    <#
    .SYNOPSIS
        Set the current ACME server and/or its configuration.

    .DESCRIPTION
        Use this function to set the current ACME server or change a server's configuration settings.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2), LE_STAGE (LetsEncrypt Staging v2), BUYPASS_PROD (BuyPass.com Production), and BUYPASS_TEST (BuyPass.com Testing).

    .PARAMETER Name
        The friendly name for this ACME server. The parameter is ignored if DirectoryUrl is specified.

    .PARAMETER NewName
        Use this to change the friendly name of this ACME server.

    .PARAMETER SkipCertificateCheck
        If specified, disable certificate validation while using this server. This should not be necessary except in development environments where you are connecting to a self-hosted ACME server.

    .PARAMETER DisableTelemetry
        If specified, telemetry data will not be sent to the Posh-ACME team for actions associated with this server. The telemetry data that gets sent by default includes Posh-ACME version, PowerShell version, and generic OS platform (Windows/Linux/MacOS).

    .PARAMETER NoRefresh
        If specified, the ACME server will not be re-queried for updated endpoints or a fresh nonce.

    .PARAMETER NoSwitch
        If specified, the currently active ACME server will not be changed to the server being modified.

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
