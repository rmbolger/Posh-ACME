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

            # Look for Retry-After header. We're not yet ready to do anything with it
            # but it can be useful for debugging.
            # https://datatracker.ietf.org/doc/html/rfc8555#section-8.2
            if ($response.Headers.ContainsKey('Retry-After')) {
                $retryAfter = $response.Headers['Retry-After']
                Write-Debug "Retry-After = $retryAfter"
            }

            ConvertTo-PAAuthorization $response.Content $AuthUrl
        }
    }
}
