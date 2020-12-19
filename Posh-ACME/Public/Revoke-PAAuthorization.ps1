function Revoke-PAAuthorization {
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('authorizations')]
        [string[]]$AuthURLs,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [switch]$Force
    )

    Begin {
        # make sure any account passed in is actually associated with the current server
        # or if no account was specified, that there's a current account.
        if (!$Account) {
            if (!($Account = Get-PAAccount)) {
                try { throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        } else {
            if ($Account.id -notin (Get-PAAccount -List).id) {
                try { throw "Specified account id $($Account.id) was not found in the current server's account list." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
        # make sure it's valid
        if ($Account.status -ne 'valid') {
            try { throw "Account status is $($Account.status)." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # build the header template
        $header = @{
            alg = $Account.alg
            kid = $Account.location
            nonce = $script:Dir.nonce
            url = [String]::Empty
        }

        # build the payload
        $payload = '{"status":"deactivated"}'

        $urls = @()
    }

    Process {

        # Because authorizations are tied to an account and potentially shared between
        # orders, we may end up with duplicate URLs that come in via the pipeline in
        # separate calls of this Process block. So instead of doing the deactivations
        # here, we're just going to collect the URLs and wait to process them in the
        # End block.

        $urls += @($AuthURLs)
    }

    End {
        # Remove any duplicates that might exist
        $urls = $urls | Select-Object -Unique

        $auths = $urls | Get-PAAuthorization -Account $Account

        # loop through the URLs and request deactivation
        foreach ($auth in $auths) {

            # don't bother with already deactivated ones
            if ('deactivated' -eq $auth.status) {
                Write-Warning "Authorization has already been deactivated for $($auth.fqdn)."
                continue
            }

            if (!$Force) {
                $msg = "Revoking an authorization prevents ordering a certificate for the identifier without proving ownership again on this account."
                $question = "Are you sure you wish to revoke the authorization for $($auth.fqdn)?"
                if (!$PSCmdlet.ShouldContinue($question,$msg)) {
                    Write-Verbose "Aborted authorization revocation for $($auth.fqdn)."
                    continue
                }
            }

            $header.nonce = $script:Dir.nonce
            $header.url = $auth.location

            Write-Verbose "Revoking authorization for $($auth.fqdn)"
            try {
                Invoke-ACME $header $payload $Account -EA Stop | Out-Null
            } catch [AcmeException] {
                Write-Error $_.Exception.Data.detail
            }

        }

    }



    <#
    .SYNOPSIS
        Revoke the authorization associated with an ACME identifier.

    .DESCRIPTION
        Many ACME server implementations cache succesful authorizations for a certain amount of time to avoid requiring an account to re-authorize identifiers for additional orders submitted during the cache window.

        This can make testing authorization challenges in a client more cumbersome by having to create new orders with uncached identifiers. This function allows you to revoke those cached authorizations so that subsequent orders will go through the full challenge validation process.

    .PARAMETER AuthURLs
        One or more authorization URLs. You also pipe in one or more PoshACME.PAOrder objects.

    .PARAMETER Account
        An existing ACME account object such as the output from Get-PAAccount. If no account is specified, the current account will be used.

    .PARAMETER Force
        If specified, no confirmation prompts will be presented.

    .EXAMPLE
        Revoke-PAAuthorization https://acme.example.com/authz/1234567

        Revoke the authorization for the specified URL using the current account.

    .EXAMPLE
        Get-PAOrder | Revoke-PAAuthorization -Force

        Revoke all authorizations for the current order on the current account without confirmation prompts.

    .EXAMPLE
        Get-PAOrder -List | Revoke-PAAuthorizations

        Revoke all authorizations for all orders on the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAuthorization

    .LINK
        Get-PAOrder

    #>
}
