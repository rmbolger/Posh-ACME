function Update-ACMEDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Uri
    )

    # because we need headers, gotta use Invoke-WebRequest until they back port 
    # PowerShell Core's -ResponseHeadersVariable parameter for Invoke-RestMethod
    $response = Invoke-WebRequest $Uri
    $dir = $response.Content | ConvertFrom-Json

    if ($dir -is [pscustomobject] -and 'newAccount' -in $dir.PSObject.Properties.name) {
        $script:dir = $dir
        $script:NextNonce = $response.Headers.'Replay-Nonce'
    } else {
        Write-Debug ($dir | ConvertTo-Json)
        throw "Unexpected ACME directory response."
    }
}
