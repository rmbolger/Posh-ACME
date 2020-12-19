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
        trap { $PSCmdlet.ThrowTerminatingError($_) }

        # make sure any account passed in is actually associated with the current server
        # or if no account was specified, that there's a current account.
        if (-not $Account) {
            if (-not ($Account = Get-PAAccount)) {
                throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
            }
        } elseif ($Account.id -notin (Get-PAAccount -List).id) {
            throw "Specified account id $($Account.id) was not found in the current server's account list."
        }
        # make sure it's valid
        if ($Account.status -ne 'valid') {
            throw "Account status is $($Account.status)."
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

            if (-not $Force) {
                $msg = "Revoking an authorization prevents ordering a certificate for the identifier without proving ownership again on this account."
                $question = "Are you sure you wish to revoke the authorization for $($auth.fqdn)?"
                if (-not $PSCmdlet.ShouldContinue($question,$msg)) {
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
}
