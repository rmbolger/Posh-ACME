function Get-Nonce {
    [CmdletBinding()]
    param(
        [string]$NewNonceUrl
    )

    # https://tools.ietf.org/html/draft-ietf-acme-acme-10#section-7.2

    # if there was no Url passed in, check if there's a saved one
    if (!$NewNonceUrl) {
        if (![string]::IsNullOrWhiteSpace($script:Dir.newNonce)) {
            $NewNonceUrl = $script:Dir.newNonce
        } else {
            throw "No newNonce Url passed in or previously saved."
        }
    }

    # super basic for now, no error checking
    Write-Verbose "Requesting new nonce from $NewNonceUrl"
    try {
        $response = Invoke-WebRequest $NewNonceUrl -Method Head -UserAgent $script:USER_AGENT -Headers $script:COMMON_HEADERS -EA Stop
    } catch { throw }

    return $response.Headers.$script:HEADER_NONCE
}
