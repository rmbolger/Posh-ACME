function Get-Nonce {
    [CmdletBinding()]
    param(
        [string]$NewNonceUri
    )

    # https://tools.ietf.org/html/draft-ietf-acme-acme-09#section-7.2

    # super basic for now, no error checking
    $response = Invoke-WebRequest $NewNonceUri -Method Head -UserAgent $script:UserAgent -Headers $script:CommonHeaders -EA Stop

    return $response.Headers.'Replay-Nonce'
}
