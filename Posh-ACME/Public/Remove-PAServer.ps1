function Remove-PAServer {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='DirUrl')]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [switch]$DeactivateAccounts,
        [switch]$Force
    )

    Process {

        if (-not $DirectoryUrl -and -not $Name) {
            try { throw "DirectoryUrl and/or Name must be specified." }
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
            $server = Get-PAServer -DirectoryUrl $DirectoryUrl -Quiet
        }
        else {
            # Try to find a server that matches Name instead
            $server = Get-PAServer -Name $Name -Quiet
        }

        # make sure we found something
        if (-not $server) {
            try { throw "No matching PAServer found on disk." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # check for existing accounts
        $accountFiles = Get-ChildItem (Join-Path $server.Folder '*\acct.json')

        # confirm deletion unless -Force was used or there are no accounts
        if (-not $Force -and $accountFiles) {
            $msg = "Deleting a server will also delete the local copies of all associated accounts, orders, and certificates associated with it."
            if ($DeactivateAccounts) {
                $msg += " You have also chosen to deactivate the associated accounts."
            }
            $question = "Are you sure you wish to delete server $($server.location)?"
            if (-not $PSCmdlet.ShouldContinue($question,$msg)) {
                Write-Verbose "Delete aborted for server $($server.location)"
                return
            }
        }

        # save the current server because we need to switch away temporarily
        $oldServer = Get-PAServer

        # switch servers if necessary
        if ($oldServer -and $server.location -ne $oldServer.location) {
            Set-PAServer -DirectoryUrl $server.location -NoRefresh
            $SwitchBack = $true
        } elseif (-not $oldServer) {
            Set-PAServer -DirectoryUrl $server.location -NoRefresh
        }

        # deactivate the accounts if requested
        if ($DeactivateAccounts) {

            $accounts = Get-PAAccount -List | Where-Object { $_.status -eq 'valid' }

            $accounts | ForEach-Object {
                try {
                    $_ | Set-PAAccount -Deactivate -Force
                } catch [AcmeException] {
                    Write-Warning "Error deactivating account $($_.id): $($_.Exception.Message)"
                }
            }
        }

        Write-Verbose "Deleting server $($server.location)"

        Write-Debug "Folder located at $($server.Folder)"
        Remove-Item $server.Folder -Force -Recurse

        if ($SwitchBack) {
            # switch back to previous server
            $oldServer | Set-PAServer
        } else {
            # nothing to switch back to, so reload empty config from disk
            Remove-Item (Join-Path (Get-ConfigRoot) 'current-server.txt') -Force
            Import-PAConfig -Level 'Server' -NoRefresh
        }
    }
}
