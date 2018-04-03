function Invoke-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=1)]
        [string]$ChallengeUrl
    )

    # hydrate the key
    $key = $Account.key | ConvertFrom-Jwk

    # build the protected header for the request
    $header = @{
        alg   = $Account.alg;
        kid   = $Account.location;
        nonce = $script:NextNonce;
        url   = $ChallengeUrl;
    }

    # the payload is an empty object
    $payloadJson = '{}'

    # send the request
    $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop

    Write-Verbose "$($response.Content)"
}
