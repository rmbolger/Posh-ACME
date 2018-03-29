function New-ACMEOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$acct,
        [Parameter(Mandatory,Position=1)]
        [string[]]$Domain
    )

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
    $response = Invoke-ACME $header.url $Key $header $payloadJson -EA Stop

    Write-Verbose "$($response.Content)"
    $ret = $response.Content | ConvertFrom-Json

    if ($response.Headers.ContainsKey('Location')) {
        Write-Verbose "Order Location: $($response.Headers['Location'])"
        # add a custom property to the return object with the location
        $ret | Add-Member -MemberType NoteProperty -Name '_location' -Value $response.Headers['Location']
    } else {
        throw 'No Location header found in newOrder output'
    }

    return $ret
}
