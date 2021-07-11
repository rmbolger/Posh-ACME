function Remove-PAServer {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='DirUrl')]
    param(
        [Parameter(ParameterSetName='DirUrl',Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ParameterSetName='Name',Mandatory)]
        [Parameter(ParameterSetName='DirUrl',ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [switch]$DeactivateAccounts,
        [switch]$Force
    )

    Process {

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
            if (!$PSCmdlet.ShouldContinue($question,$msg)) {
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
            Import-PAConfig -Level 'Server'
        }
    }





    <#
    .SYNOPSIS
        Remove an ACME server and all associated accounts, orders, and certificates from the local profile.

    .DESCRIPTION
        This function removes the ACME server from the local profile which also removes any associated accounts, orders and certificates. It will not remove or cleanup copies of certificates that have been exported or installed elsewhere. It will not revoke any certificates that are still valid. It will not deactivate the accounts on the ACME server unless the -DeactivateAccounts switch is specified.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2).

    .PARAMETER Name
        The friendly name for this ACME server. The parameter is ignored if DirectoryUrl is specified.

    .PARAMETER DeactivateAccounts
        If specified, an attempt will be made to deactivate the accounts in this profile before deletion. Clients may wish to do this if the account key is compromised or being decommissioned.

    .PARAMETER Force
        If specified, interactive confirmation prompts will be skipped.

    .EXAMPLE
        Remove-PAAccount LE_STAGE

        Remove the staging server without deactivating accounts.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAServer

    .LINK
        Set-PAServer

    #>
}
