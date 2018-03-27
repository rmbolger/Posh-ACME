function New-ACMEOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({Test-ValidKey $_ -ThrowOnFail})]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
        [Parameter(Mandatory,Position=1)]
        [string[]]$Domain
    )

    # make a variable shortcut to the current server's config
    $curcfg = $script:cfg.($script:cfg.CurrentDir)

    # build the protected header for the request
    $header = @{
        alg   = (Get-JwsAlg $Key);
        kid   = $curcfg.AccountUri;
        nonce = $script:NextNonce;
        url   = $script:dir.newOrder;
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
    return ($response.Content | ConvertFrom-Json)
}