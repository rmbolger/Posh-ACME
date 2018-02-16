function Update-ACMEDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Uri
    )

    # because we need headers, gotta use Invoke-WebRequest until they back port 
    # PowerShell Core's -ResponseHeadersVariable parameter for Invoke-RestMethod
    Write-Verbose "Updating directory info from $Uri"
    $response = Invoke-WebRequest $Uri
    $dir = $response.Content | ConvertFrom-Json

    if ($dir -is [pscustomobject] -and 'newAccount' -in $dir.PSObject.Properties.name) {
        $script:dir = $dir

        # grab the next nonce
        if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
            $script:NextNonce = $response.Headers.$script:HEADER_NONCE
        } else {
            $Script:NextNonce = Get-Nonce
        }
    } else {
        Write-Verbose ($dir | ConvertTo-Json)
        throw "Unexpected ACME directory response."
    }
}
