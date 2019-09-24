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
        # build the header for the Post-As-Get request
        $header = @{
            alg   = $acct.alg;
            kid   = $acct.location;
            nonce = $script:Dir.nonce;
            url   = $Order.certificate;
        }

        # download the cert+chain which is what ACMEv2 delivers by default
        # https://tools.ietf.org/html/rfc8555#section-7.4.2
        try {
            Invoke-ACME $header ([String]::Empty) $acct -OutFile $fullchainFile -EA Stop
        } catch { throw }

        # split it into individual PEMs
        $pems = Split-PemChain $fullchainFile

        # write the lone cert
        Export-Pem $pems[0] $certFile

        # write the chain
        Export-Pem ($pems[1..($pems.Count-1)] | ForEach-Object {$_}) $chainFile
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
