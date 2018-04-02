function Update-PAAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAAccount')]$acct
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    Write-Verbose "Refreshing account $($acct.id) $($acct.alg)"

    # hydrate the key
    $key = $acct.key | ConvertFrom-Jwk

    # build the header
    $header = @{
        alg   = $acct.alg;
        kid   = $acct.location;
        nonce = $script:NextNonce;
        url   = $acct.location;
    }

    # empty payload
    $payloadJson = '{}'

    # send the request
    $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop
    Write-Verbose $response.Content

    $respObj = ($response.Content | ConvertFrom-Json);

    # update the things that could have changed
    $acct.status = $respObj.status
    $acct.contact = $respObj.contact
    $acct.orderlocation = $respObj.orders

    # save it to disk
    $acctFolder = Join-Path $script:DirFolder $acct.id
    $acct | ConvertTo-Json | Out-File (Join-Path $acctFolder 'acct.json') -Force

}
