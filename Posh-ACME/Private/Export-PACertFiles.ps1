function Export-PACertFiles {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [switch]$PfxOnly
    )

    # Make sure we have an account configured
    if (!($acct = Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
    }

    # Make sure we have an order
    if (-not $Order -and !($Order = Get-PAOrder)) {
        throw "No ACME order specified and no current order selected. Run Set-PAOrder or specify an existing order object."
    }
    $orderFolder = Join-Path $script:AcctFolder $Order.MainDomain.Replace('*','!')

    # build output paths
    $certFile      = Join-Path $orderFolder 'cert.cer'
    $keyFile       = Join-Path $orderFolder 'cert.key'
    $chainFile     = Join-Path $orderFolder 'chain.cer'
    $fullchainFile = Join-Path $orderFolder 'fullchain.cer'
    $pfxFile       = Join-Path $orderFolder 'cert.pfx'
    $pfxFullFile   = Join-Path $orderFolder 'fullchain.pfx'

    if (-not $PfxOnly) {

        # Re-download the cert/chains if the order has not expired.
        if ((Get-DateTimeOffsetNow) -lt [DateTimeOffset]::Parse($order.expires)) {

            # build the header for the Post-As-Get request
            $header = @{
                alg   = $acct.alg
                kid   = $acct.location
                nonce = $script:Dir.nonce
                url   = $Order.certificate
            }

            # download the cert+chain which is what ACMEv2 delivers by default
            # https://tools.ietf.org/html/rfc8555#section-7.4.2
            try {
                $response = Invoke-ACME $header ([String]::Empty) $acct -EA Stop
            } catch { throw }

            $pems = Split-PemChain -ChainBytes $response.Content

            # write the lone cert
            Export-Pem $pems[0] $certFile

            # write the primary chain as chain0.cer
            $chain0File = Join-Path $orderFolder 'chain0.cer'
            Export-Pem ($pems[1..($pems.Count-1)] | ForEach-Object {$_}) $chain0File

            # check for alternate chain header links
            $links = @(Get-AlternateLinks $response.Headers)

            # download the alternate chains
            for ($i = 0; $i -lt $links.Count; $i++) {
                Write-Debug "Alt Chain $($i+1): $($links[$i])"
                $header.url = $links[$i]
                $header.nonce = $script:Dir.nonce

                try {
                    $response = Invoke-ACME $header ([String]::Empty) $acct -EA Stop
                } catch {throw}
                $pems = Split-PemChain -ChainBytes $response.Content

                # write additional chain files as chain1.cer,chain2.cer,etc.
                $altChainFile = Join-Path $orderFolder "chain$($i+1).cer"
                Export-Pem ($pems[1..($pems.Count-1)] | ForEach-Object {$_}) $altChainFile
            }
        }
        else {
            Write-Warning "Order has expired. Unable to re-download cert/chain files. Using cached copies."
        }

        # try to find the chain file matching the preferred issuer if specified
        if (-not ([String]::IsNullOrWhiteSpace($order.PreferredChain))) {
            $selectedChainFile = Get-ChainIssuers $orderFolder |
                Where-Object { $_.issuer -eq $order.PreferredChain } |
                Select-Object -First 1 -Expand filePath
            Write-Debug "Preferred chain, $($order.PreferredChain), matched: $selectedChainFile"

            if (-not $selectedChainFile) {
                Write-Warning "The preferred chain issuer, $($order.PreferredChain), was not found. Using the default chain."
                $selectedChainFile = $chain0File
            }
        } else {
            $selectedChainFile = $chain0File
        }

        # build the appropriate chain and fullchain files
        Copy-Item $selectedChainFile $chainFile
        $fullchainLines = (Get-Content $certFile) + (Get-Content $selectedChainFile)
        Export-Pem $fullchainLines $fullchainFile
    }

    # When using an pre-generated CSR file, there may be no private key.
    # So make sure we have a one before we try to generate PFX files.
    if (Test-Path $keyFile -PathType Leaf) {

        $pfxParams = @{
            CertFile     = $certFile;
            KeyFile      = $keyFile;
            OutputFile   = $pfxFile;
            FriendlyName = $Order.FriendlyName;
            PfxPass      = $Order.PfxPass;
        }
        Export-CertPfx @pfxParams
        $pfxParams.OutputFile = $pfxFullFile
        Export-CertPfx @pfxParams -ChainFile $chainFile

    } else {
        Write-Verbose "No private key available. Skipping Pfx creation."
    }
}
