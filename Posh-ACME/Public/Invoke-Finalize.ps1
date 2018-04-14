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

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # hydrate the key
    $key = $Account.key | ConvertFrom-Jwk

    # build the protected header
    $header = @{
        alg   = $Account.alg;
        kid   = $Account.location;
        nonce = $script:Dir.nonce;
        url   = $Order.finalize;
    }

    $payloadJson = "{`"csr`":`"$CSR`"}"

    # send the request
    $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop
    Write-Verbose "$($response.Content)"

    # Boulder's ACME implementation (at least on Staging) currently doesn't
    # quite follow the spec at this point. What I've observed is that the
    # response to the finalize request is indeed the order object and it appears
    # to have 'valid' status and a URL for the certificate. It skips the 'processing'
    # status entirely which we shouldn't rely on according to the spec.
    #
    # So, we start polling the order directly, and the first response comes back with
    # 'valid' status, but no certificate URL. Not sure if that means the previous
    # certificate URL was invalid. But we ultimately need to check for both 'valid'
    # status and a certificate URL to return.

    # now we poll
    for ($tries=1; $tries -le ($SecondsToWait/2); $tries++) {

        $Order = Get-PAOrder $Order.MainDomain -Refresh

        if ($Order.status -eq 'invalid') {
            throw "Order status for $($Order.MainDomain) is invalid."
        } elseif ($Order.status -eq 'valid' -and ![string]::IsNullOrWhiteSpace($Order.certificate)) {
            return $Order
        } else {
            # According to spec, the only other statuses are pending, ready, or processing
            # which means we should wait more.
            Start-Sleep 2
        }

    }

    # If we're here, it means our poll timed out because we didn't return. So throw.
    throw "Timed out waiting $SecondsToWait seconds for order to become valid."

}
