function Remove-PAServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('location')]
        [string]$DirectoryUrl,
        [switch]$DeactivateAccounts,
        [switch]$Force
    )

    Process {

        # convert WellKnown names to their associated Url
        if ($DirectoryUrl -notlike 'https://*') {
            $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
        }
        Write-Debug "Using DirectoryUrl $DirectoryUrl"

        # Make sure the server exists on disk
        $dirFolder = ConvertTo-DirFolder $DirectoryUrl
        if (-not (Test-Path $dirFolder -PathType Container)) {
            throw "Server $DirectoryUrl does not have an associated config folder. Nothing to delete."
        }

        # confirm deletion unless -Force was used
        if (!$Force) {
            $msg = "Deleting a server will also delete all associated accounts, orders, and certificates associated with it."
            if ($DeactivateAccounts) {
                $msg += " You have also chosen to deactivate the associated accounts."
            }
            $question = "Are you sure you wish to delete server $DirectoryUrl?"
            if (!$PSCmdlet.ShouldContinue($question,$msg)) {
                Write-Verbose "Delete aborted for server $DirectoryUrl"
                return
            }
        }

        # save the current server because we need to switch away temporarily
        $oldServer = Get-PAServer

        # switch servers if necessary
        if ($oldServer -and $DirectoryUrl -ne $oldServer.location) {
            Get-PAServer $DirectoryUrl | Set-PAServer
            $SwitchBack = $true
        } elseif (-not $oldServer) {
            Get-PAServer $DirectoryUrl | Set-PAServer
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

        Write-Verbose "Deleting server $DirectoryUrl"

        $dirFolder = Get-DirFolder
        Write-Debug "Folder located at $dirFolder"
        Remove-Item $dirFolder -Force -Recurse

        if ($SwitchBack) {
            # switch back to previous server
            $oldServer | Set-PAServer
        } else {
            # nothing to switch back to, so reload empty config from disk
            Remove-Item (Join-Path (Get-ConfigRoot) 'current-server.txt') -Force
            Import-PAConfig
        }
    }





    <#
    .SYNOPSIS
        Remove an ACME server and all associated accounts, orders, and certificates from the local profile.

    .DESCRIPTION
        This function removes the ACME server from the local profile which also removes any associated accounts, orders and certificates. It will not remove or cleanup copies of certificates that have been exported or installed elsewhere. It will not revoke any certificates that are still valid. It will not deactivate the accounts on the ACME server unless the -DeactivateAccounts switch is specified.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2).

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
