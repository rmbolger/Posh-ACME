function New-PAOrder {
    [OutputType('PoshACME.PAOrder')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='4096',
        [switch]$Force
    )

    $acct = Get-PAAccount

    # Make sure we have an account configured
    if (!$acct) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    # There's a chance we may be overwriting an existing order here. So check for
    # confirmation if certain conditions are true
    $order = Get-PAOrder $Domain[0] -Refresh
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object

    # skip confirmation if -Force was used or the SANs or KeyLength are different 
    # regardless of the original order status
    if ( $Force -or ($order -and ($KeyLength -ne $order.KeyLength -or
         ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') ))) {
        # do nothing

    # confirm if previous order is still in progress
    } elseif ($order -and $order.status -in 'pending','ready','processing') {

        if (!$PSCmdlet.ShouldContinue("Do you wish to overwrite?",
            "Existing order with status $($order.status).")) { return }

    # confirm if previous order not up for renewal
    } elseif ($order -and $order.status -eq 'valid' -and (Get-Date) -lt (Get-Date $order.RenewAfter)) {

        if (!$PSCmdlet.ShouldContinue("Do you wish to overwrite?",
            "Existing order has not reached renewal window.")) { return }
    }

    # convert the key
    $acctKey = $acct.key | ConvertFrom-Jwk

    # build the protected header for the request
    $header = @{
        alg   = $acct.alg;
        kid   = $acct.location;
        nonce = $script:NextNonce;
        url   = $script:Dir.newOrder;
    }

    # build the payload object
    $payload = @{identifiers=@()}
    foreach ($d in $Domain) {
        $payload.identifiers += @{type='dns';value=$d}
    }
    $payloadJson = $payload | ConvertTo-Json -Compress

    # send the request
    $response = Invoke-ACME $header.url $acctKey $header $payloadJson -EA Stop

    # process the response
    Write-Verbose "$($response.Content)"
    $order = $response.Content | ConvertFrom-Json
    $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
    $order | Add-Member -MemberType NoteProperty -Name 'MainDomain' -Value $Domain[0]
    $order | Add-Member -MemberType NoteProperty -Name 'SANs' -Value $SANs
    $order | Add-Member -MemberType NoteProperty -Name 'KeyLength' -Value $KeyLength
    $order | Add-Member -MemberType NoteProperty -Name 'RenewAfter' -Value $null

    # add the location from the header
    if ($response.Headers.ContainsKey('Location')) {
        Write-Verbose "Adding location $($response.Headers['Location'])"
        $order | Add-Member -MemberType NoteProperty -Name 'location' -Value $response.Headers['Location']
    } else {
        throw 'No Location header found in newOrder output'
    }

    # save it to memory and disk
    $order.MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force
    $script:Order = $order
    $script:OrderFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
    if (!(Test-Path $script:OrderFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $script:OrderFolder -Force | Out-Null
    }
    $order | ConvertTo-Json | Out-File (Join-Path $script:OrderFolder 'order.json') -Force

    return $order
}
