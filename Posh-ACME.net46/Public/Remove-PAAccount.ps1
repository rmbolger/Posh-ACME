function Remove-PAAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ID,
        [switch]$Deactivate,
        [switch]$Force
    )

    Begin {
        # make sure we have a server configured
        if (!(Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }
    }

    Process {
        # grab a copy of the account
        if (!($acct = Get-PAAccount $ID)) {
            Write-Warning "Specified account ID ($ID) was not found."
            return
        }

        # deactivate first, if asked
        if ($Deactivate -and $acct.status -eq 'valid') {
            $acct | Set-PAAccount -Deactivate -NoSwitch -Force:$Force.IsPresent
        }

        # confirm deletion unless -Force was used
        if (!$Force) {
            $msg = "Deleting an account will also delete all associated orders and certificates."
            $question = "Are you sure you wish to delete account $($acct.id)?"
            if (!$PSCmdlet.ShouldContinue($question,$msg)) {
                Write-Verbose "Deletion aborted for account $($acct.id)."
                return
            }
        }

        Write-Verbose "Deleting account $($acct.id)"

        # delete the account's folder
        $acctFolder = Join-Path (Get-DirFolder) $acct.id
        Remove-Item $acctFolder -Force -Recurse

        # unset the current account if it was this one
        if ($script:Acct -and $script:Acct.id -eq $acct.id) {
            $script:Acct = $null
            $script:AcctFolder = $null
            $acct = $null
            $script:Order = $null
            $script:OrderFolder = $null

            Remove-Item (Join-Path (Get-DirFolder) 'current-account.txt') -Force
        }

    }





    <#
    .SYNOPSIS
        Remove an ACME account and all associated orders and certificates from the local profile.

    .DESCRIPTION
        This function removes the ACME account from the local profile which also removes any associated orders and certificates. It will not remove or cleanup copies of certificates that have been exported or installed elsewhere. It will also not deactivate the account on the ACME server without using -Deactivate. However, with the account's private key it can't be recovered from the server.

    .PARAMETER ID
        The account id value as returned by the ACME server.

    .PARAMETER Deactivate
        If specified, a request will be sent to the associated ACME server to deactivate the account. Clients may wish to do this if the account key is compromised or decommissioned.

    .PARAMETER Force
        If specified, interactive confirmation prompts will be skipped.

    .EXAMPLE
        Remove-PAAccount 12345

        Remove the specified account without deactivation.

    .EXAMPLE
        Get-PAAccount | Remove-PAAccount -Deactivate -Force

        Remove the current account after deactivating it and skip confirmation prompts.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAccount

    .LINK
        New-PAAccount

    #>
}
