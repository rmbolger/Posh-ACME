function Update-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Url
    )

    # Because we need headers, must use Invoke-WebRequest until MS back ports
    # PowerShell Core's -ResponseHeadersVariable parameter for Invoke-RestMethod

    Write-Verbose "Updating directory info from $Url"
    $response = Invoke-WebRequest $Url -Verbose:$false
    $dir = $response.Content | ConvertFrom-Json

    if ($dir -is [pscustomobject] -and 'newAccount' -in $dir.PSObject.Properties.name) {
        $script:Dir = $dir

        # grab the next nonce
        if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
            $script:NextNonce = $response.Headers.$script:HEADER_NONCE
        } else {
            $Script:NextNonce = Get-Nonce $Url
        }
    } else {
        Write-Verbose ($dir | ConvertTo-Json)
        throw "Unexpected ACME directory response."
    }
}
