function Get-PAAuthorization {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('authorizations')]
        [string[]]$AuthURLs,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    Begin {
        # Make sure there's a valid account
        if (-not $Account) {
            if (-not ($Account = Get-PAAccount)) {
                try { throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
        if ($Account.status -ne 'valid') {
            try { throw "Account status is $($Account.status)." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {
        foreach ($AuthUrl in $AuthUrls) {

            # request the object
            try {
                $header = @{
                    alg   = $Account.alg
                    kid   = $Account.location
                    nonce = $script:Dir.nonce
                    url   = $AuthUrl
                }
                $response = Invoke-ACME $header ([String]::Empty) $Account -EA Stop
            } catch [AcmeException] {
                if ($_.Exception.Data.status -eq 404) {
                    Write-Warning "Authorization not found on server. $($_.Exception.Data.detail)"
                    continue
                } else { throw }
            }

            ConvertTo-PAAuthorization $response.Content $AuthUrl
        }
    }





    <#
    .SYNOPSIS
        Get the authorizations associated with a particular order or set of authorization URLs.

    .DESCRIPTION
        Returns details such as fqdn, status, expiration, and challenges for one or more ACME authorizations.

    .PARAMETER AuthURLs
        One or more authorization URLs. These will be picked up automatically if you send PoshACME.PAOrder objects through the pipeline.

    .PARAMETER Account
        An existing ACME account object such as the output from Get-PAAccount. If no account is specified, the current account will be used.

    .EXAMPLE
        Get-PAAuthorization https://acme.example.com/authz/1234567

        Get the authorization for the specified URL.

    .EXAMPLE
        Get-PAOrder | Get-PAAuthorization

        Get the authorization(s) for the current order on the current account.

    .EXAMPLE
        Get-PAOrder -List | Get-PAAuthorization

        Get the authorization(s) for all orders on the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
