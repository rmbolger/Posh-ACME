function Invoke-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$acct,
        [Parameter(Mandatory,Position=1)]
        [string]$ChallengeUrl
    )

    # build the protected header for the request
    $header = @{
        alg   = $acct.alg;
        kid   = $acct.location;
        nonce = $script:NextNonce;
        url   = $ChallengeUrl;
    }

    # the payload is an empty object
    $payloadJson = '{}'

    # send the request
    $response = Invoke-ACME $header.url $Key $header $payloadJson -EA Stop

    Write-Verbose "$($response.Content)"
}
