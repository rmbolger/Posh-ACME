function Invoke-Finalize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=1)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [Parameter(Mandatory,Position=2)]
        [string]$CSR,
        [int]$SecondsToWait=60
    )

    # The purpose of this function is to complete the order process by sending our
    # certificate request and wait for it to generate the signed cert. We'll poll
    # the order until it's valid, invalid, or our timeout elapses.

    # hydrate the key
    $key = $Account.key | ConvertFrom-Jwk

    # build the protected header
    $header = @{
        alg   = $Account.alg;
        kid   = $Account.location;
        nonce = $script:NextNonce;
        url   = $Order.finalize;
    }

    $payloadJson = "{`"csr`":`"$CSR`"}"

    # send the request
    $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop
    Write-Verbose "$($response.Content)"

    # now we poll
    for ($tries=1; $tries -le ($SecondsToWait/2); $tries++) {

        $Order = Get-PAOrder $Order.MainDomain -Refresh

        if ($Order.status -eq 'invalid') {
            throw "Order status for $($Order.MainDomain) is invalid."
        } elseif ($Order.status -eq 'valid') {
            return $Order
        } else {
            # According to spec, the only other statuses are pending, ready, or processing
            # which means we should wait more.
            Start-Sleep 2
        }

    }

}
