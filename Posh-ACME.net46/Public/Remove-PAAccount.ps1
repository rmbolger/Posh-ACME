function Remove-PAAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [Alias('Name')]
        [string]$ID,
        [switch]$Deactivate,
        [switch]$Force
    )

    Begin {
        # make sure we have a server configured
        if (-not ($server = Get-PAServer)) {
            try { throw "No ACME server configured. Run Set-PAServer first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {
        # grab a copy of the account
        if (-not ($acct = Get-PAAccount -ID $ID)) {
            Write-Warning "Specified account ID ($ID) was not found."
            return
        }

        # deactivate first, if asked
        if ($Deactivate -and $acct.status -eq 'valid') {
            $acct | Set-PAAccount -Deactivate -NoSwitch -Force:$Force.IsPresent
        }

        # confirm deletion unless -Force was used
        if (-not $Force) {
            $msg = "Deleting an account will also delete all local copies of orders and certificates. But they may still exist on the ACME server."
            $question = "Are you sure you wish to delete account $($acct.id)?"
            if (-not $PSCmdlet.ShouldContinue($question,$msg)) {
                Write-Verbose "Deletion aborted for account $($acct.id)."
                return
            }
        }

        Write-Verbose "Deleting account $($acct.id)"

        # delete the account's folder
        $acctFolder = Join-Path $server.Folder $acct.id
        Remove-Item $acctFolder -Force -Recurse

        # unset the current account if it was this one
        if ($script:Acct -and $script:Acct.id -eq $acct.id) {
            $acct = $null
            Remove-Item (Join-Path $server.Folder 'current-account.txt') -Force
            Import-PAConfig -Level 'Account'
        }

    }
}
