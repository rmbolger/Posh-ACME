function Update-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$order
    )

    # Make sure we have an account configured
    if (!(Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    Write-Verbose "Refreshing order $($order.MainDomain)"

    # we can request the order info via an anonymous GET request
    try {
        $response = Invoke-WebRequest $order.location -Verbose:$false -ErrorAction Stop
    } catch { throw }
    $respObj = $response.Content | ConvertFrom-Json

    # update the things that could have changed
    $order.status = $respObj.status
    $order.expires = $respObj.expires
    if ($order.status -eq 'valid') {
        $order.RenewAfter = (Get-Date $order.expires).ToUniversalTime().AddDays(-30).ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    if ($respObj.certificate) {
        $order.certificate = $respObj.certificate
    }

    # save it to disk
    $orderFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
    $order | ConvertTo-Json | Out-File (Join-Path $orderFolder 'order.json') -Force

}
