function New-PAOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain
    )

    $acct = Get-PAAccount

    # Make sure we have an account configured
    if (!$acct) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    # convert the key
    $key = $acct.key | ConvertFrom-Jwk

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
    $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop

    # process the response
    Write-Verbose "$($response.Content)"
    $order = $response.Content | ConvertFrom-Json
    $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
    $order | Add-Member -MemberType NoteProperty -Name 'MainDomain' -Value $Domain[0]
    $order | Add-Member -MemberType NoteProperty -Name 'SANs' -Value @($Domain | ?{ $_ -ne $Domain[0] })
    $order | Add-Member -MemberType NoteProperty -Name 'KeyLength' -Value $null
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
