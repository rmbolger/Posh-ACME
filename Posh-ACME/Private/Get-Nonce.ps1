function Get-Nonce {
    [CmdletBinding()]
    param(
        [string]$NewNonceUri
    )

    # https://tools.ietf.org/html/draft-ietf-acme-acme-09#section-7.2

    # if there was no Uri passed in, check if there's a saved one
    if (!$NewNonceUri) {
        if (![string]::IsNullOrWhiteSpace($script:NewNonceUri)) {
            $NewNonceUri = $script:NewNonceUri
        } else {
            throw "No newNonce Uri passed in or previously saved."
        }
    }

    # super basic for now, no error checking
    $response = Invoke-WebRequest $NewNonceUri -Method Head -UserAgent $script:UserAgent -Headers $script:CommonHeaders -EA Stop

    # save the last used Uri
    $script:NewNonceUri = $NewNonceUri

    return $response.Headers.'Replay-Nonce'
}
