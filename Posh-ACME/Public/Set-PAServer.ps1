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
        [switch]$UseAltAccountRefresh,
        [switch]$DisableARI,
        [switch]$IgnoreContacts,
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
                # save the shortcut to use as the default name
                $shortcutName = $DirectoryUrl
                Write-Debug "$DirectoryUrl converted to $($script:WellKnownDirs.$DirectoryUrl)"
                $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
            }

            # ignore the Name parameter when DirectoryUrl is specified
            $newDir = Get-PAServer -DirectoryUrl $DirectoryUrl -Quiet

            # if a cached server doesn't exist, create the basics of a new one
            # that we'll fully populate later
            if (-not $newDir) {

                if (-not $Name) {
                    # generate a default name using the shortcut if it was specified,
                    # otherwise the Host value of the URL
                    $uri = [uri]$DirectoryUrl
                    $Name = if ($shortcutName) {
                        $shortcutName
                    } else {
                        ('{0}_{1}' -f $uri.Host,$uri.Port).Replace('_443','')
                    }
                }

                # make sure another server doesn't exist with this name already
                if (Get-PAServer -Name $Name -Quiet) {
                    try { throw "Another server already exists with Name '$Name'. Please specify a unique value." }
                    catch { $PSCmdlet.ThrowTerminatingError($_) }
                }

                $newDir = [pscustomobject]@{
                    PSTypeName = 'PoshACME.PAServer'
                    location = $DirectoryUrl
                    Name = $Name
                    Folder = Join-Path (Get-ConfigRoot) $Name
                    DisableTelemetry = $DisableTelemetry.IsPresent
                    SkipCertificateCheck = $SkipCertificateCheck.IsPresent
                    UseAltAccountRefresh = $UseAltAccountRefresh.IsPresent
                    DisableARI = $DisableARI.IsPresent
                    IgnoreContacts = $IgnoreContacts.IsPresent
                    newAccount = $null
                    newOrder = $null
                    newNonce = $null
                    keyChange = $null
                    revokeCert = $null
                    meta = $null
                    nonce = $null
                }

                # If UseAltAccountRefresh wasn't specified, set it to true by default
                # for CAs we know have problems like Google, SSL.com, and DigiCert
                if (-not $PSBoundParameters.ContainsKey('UseAltAccountRefresh') -and
                    ($DirectoryUrl -like '*.pki.goog/*' -or
                     $DirectoryUrl -like '*.ssl.com/*' -or
                     $DirectoryUrl -like '*.digicert.com/*')
                ) {
                    $newDir.UseAltAccountRefresh = $true
                    $UseAltAccountRefresh = [switch]::Present
                }

                # If IgnoreContacts wasn't specified, set it to true by default
                # for CAs that don't support the account-level contacts field
                # such as Let's Encrypt.
                if (-not $PSBoundParameters.ContainsKey('IgnoreContacts') -and
                    ($DirectoryUrl -like '*.letsencrypt.org/*')
                ) {
                    $newDir.IgnoreContacts = $true
                    $IgnoreContacts = [switch]::Present
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
            Set-CertValidation -Skip $SkipCertificateCheck.IsPresent
        }
        elseif ($curDir -and $curDir.SkipCertificateCheck) {
            Set-CertValidation -Skip $true
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

            # check for the renewalInfo field
            if ($dirObj.renewalInfo) {
                $newDir | Add-Member 'renewalInfo' $dirObj.renewalInfo -Force
            }


            # update the nonce value
            if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
                $newDir.nonce = $response.Headers[$script:HEADER_NONCE] | Select-Object -First 1
            } else {
                $newDir.nonce = Get-Nonce $dirObj.newNonce
            }
        }

        # update switch param details if specified and necessary
        if ($PSBoundParameters.ContainsKey('DisableTelemetry') -and
            $newDir.DisableTelemetry -ne $DisableTelemetry.IsPresent)
        {
            Write-Debug "Setting DisableTelemetry value to $($DisableTelemetry.IsPresent)"
            $newDir | Add-Member 'DisableTelemetry' $DisableTelemetry.IsPresent -Force
        }
        if ($PSBoundParameters.ContainsKey('SkipCertificateCheck') -and
            $newDir.SkipCertificateCheck -ne $SkipCertificateCheck.IsPresent)
        {
            Write-Debug "Setting SkipCertificateCheck value to $($SkipCertificateCheck.IsPresent)"
            $newDir | Add-Member 'SkipCertificateCheck' $SkipCertificateCheck.IsPresent -Force
        }
        if ($PSBoundParameters.ContainsKey('UseAltAccountRefresh') -and
            $newDir.UseAltAccountRefresh -ne $UseAltAccountRefresh.IsPresent)
        {
            Write-Debug "Setting UseAltAccountRefresh value to $($UseAltAccountRefresh.IsPresent)"
            $newDir | Add-Member 'UseAltAccountRefresh' $UseAltAccountRefresh.IsPresent -Force
        }
        if ($PSBoundParameters.ContainsKey('DisableARI') -and
            $newDir.DisableARI -ne $DisableARI.IsPresent)
        {
            Write-Debug "Setting DisableARI value to $($DisableARI.IsPresent)"
            $newDir | Add-Member 'DisableARI' $DisableARI.IsPresent -Force
        }
        if ($PSBoundParameters.ContainsKey('IgnoreContacts') -and
            $newDir.IgnoreContacts -ne $IgnoreContacts.IsPresent)
        {
            Write-Debug "Setting IgnoreContacts value to $($IgnoreContacts.IsPresent)"
            $newDir | Add-Member 'IgnoreContacts' $IgnoreContacts.IsPresent -Force
        }

        # save the object to disk except for the dynamic properties
        Write-Debug "Saving PAServer to disk"
        $dirFile = Join-Path $newDir.Folder 'dir.json'
        $newDir | Select-Object -Property * -ExcludeProperty Name,Folder |
            ConvertTo-Json -Depth 5 |
            Out-File $dirFile -Force -EA Stop

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
}
