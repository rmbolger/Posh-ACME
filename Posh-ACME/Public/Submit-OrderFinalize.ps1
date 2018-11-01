function Submit-OrderFinalize {
    [CmdletBinding()]
    param(
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # The purpose of this function is to complete the order process by sending our
    # certificate request and wait for it to generate the signed cert. We'll poll
    # the order until it's valid, invalid, or our timeout elapses.

    # make sure any account passed in is actually associated with the current server
    # or if no account was specified, that there's a current account.
    if (!$Account) {
        if (!($Account = Get-PAAccount)) {
            throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
        }
    } else {
        if ($Account.id -notin (Get-PAAccount -List).id) {
            throw "Specified account id $($Account.id) was not found in the current server's account list."
        }
    }
    # make sure it's valid
    if ($Account.status -ne 'valid') {
        throw "Account status is $($Account.status)."
    }

    # make sure any order passed in is actually associated with the account
    # or if no order was specified, that there's a current order.
    if (!$Order) {
        if (!($Order = Get-PAOrder)) {
            throw "No Order parameter specified and no current order selected. Try running Set-PAOrder first."
        }
    } else {
        if ($Order.MainDomain -notin (Get-PAOrder -List).MainDomain) {
            throw "Specified order for $($Order.MainDomain) was not found in the current account's order list."
        }
    }

    # Use the provided CSR if it exists
    # or generate one if necessary.
    if ([String]::IsNullOrWhiteSpace($order.CSRBase64Url)) {
        Write-Verbose "Creating new certificate request with key length $($Order.KeyLength)$(if ($Order.OCSPMustStaple){' and OCSP Must-Staple'})."
        $csr = New-Csr $Order
    } else {
        Write-Verbose "Using the provided certificate request."
        $csr = $order.CSRBase64Url
    }

    # build the protected header
    $header = @{
        alg   = $Account.alg;
        kid   = $Account.location;
        nonce = $script:Dir.nonce;
        url   = $Order.finalize;
    }

    # send the request
    try {
        $response = Invoke-ACME $header "{`"csr`":`"$csr`"}" $Account -EA Stop
    } catch { throw }
    Write-Debug "Response: $($response.Content)"

    # Boulder's ACME implementation (at least on Staging) currently doesn't
    # quite follow the spec at this point. What I've observed is that the
    # response to the finalize request is indeed the order object and it appears
    # to have 'valid' status and a URL for the certificate. It skips the 'processing'
    # status entirely which we shouldn't rely on according to the spec.
    #
    # So we start polling the order directly and the first response comes back with
    # 'valid' status, but no certificate URL. Not sure if that means the previous
    # certificate URL was invalid. But we ultimately need to check for both 'valid'
    # status and a certificate URL to return.

    # now we poll
    for ($tries=1; $tries -le 30; $tries++) {

        $Order = Get-PAOrder $Order.MainDomain -Refresh

        if ($Order.status -eq 'invalid') {
            throw "Order status for $($Order.MainDomain) is invalid."
        } elseif ($Order.status -eq 'valid' -and ![string]::IsNullOrWhiteSpace($Order.certificate)) {
            return
        } else {
            # According to spec, the only other statuses are pending, ready, or processing
            # which means we should wait more.
            Start-Sleep 2
        }

    }

    # If we're here, it means our poll timed out because we didn't return already. So throw.
    throw "Timed out waiting for order to become valid."





    <#
    .SYNOPSIS
        Finalize a certificate order

    .DESCRIPTION
        Finalizing a certificate order will send a new certificate request to the server and then wait for it to become valid or invalid.

    .PARAMETER Account
        If specified, switch to and use this account for the finalization. It must be associated with the current server or an error will be thrown.

    .PARAMETER Order
        If specified, switch to and use this order for the finalization. It must be associated with the current or specified account or an error will be thrown.

    .EXAMPLE
        Submit-OrderFinalize

        Submit the finalize request using the current order, account, and private key if it exists.

    .EXAMPLE
        $order = Get-PAOrder site1.example.com
        PS C:\>Submit-OrderFinalize -Order $order

        Submit the finalize request using the specified order on the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        Submit-ChallengeValidation

    #>
}
