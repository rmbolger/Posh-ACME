function Get-Nonce {
    [CmdletBinding()]
    param(
        [string]$NewNonceUri
    )

    # https://tools.ietf.org/html/draft-ietf-acme-acme-09#section-7.2

    # if there was no Uri passed in, check if there's a saved one
    if (!$NewNonceUri) {
        if (![string]::IsNullOrWhiteSpace($script:dir.newNonce)) {
            $NewNonceUri = $script:dir.newNonce
        } else {
            throw "No newNonce Uri passed in or previously saved."
        }
    }

    # super basic for now, no error checking
    Write-Verbose "Requesting new nonce from $NewNonceUri"
    $response = Invoke-WebRequest $NewNonceUri -Method Head -UserAgent $script:UserAgent -Headers $script:CommonHeaders -EA Stop

    return $response.Headers.$script:HEADER_NONCE
}
