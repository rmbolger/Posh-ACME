function New-ACMEOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain
    )

    # make a variable shortcut to the current server's config
    $curcfg = $script:cfg.($script:cfg.CurrentDir)

    # build the protected header for the request
    $header = @{
        alg   = $curcfg.AccountAlg;
        kid   = $curcfg.AccountUri;
        nonce = $script:NextNonce;
        url   = $script:dir.newOrder;
    }

    Write-Verbose "$(($header |ConvertTo-Json))"

}