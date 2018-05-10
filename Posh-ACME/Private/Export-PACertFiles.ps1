function Export-PACertFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$CertUrl,
        [Parameter(Mandatory,Position=1)]
        [string]$OutputFolder,
        [string]$FriendlyName=''
    )

    # build output paths
    $certFile      = Join-Path $OutputFolder 'cert.cer'
    $keyFile       = Join-Path $OutputFolder 'cert.key'
    $chainFile     = Join-Path $OutputFolder 'chain.cer'
    $fullchainFile = Join-Path $OutputFolder 'fullchain.cer'
    $pfxFile       = Join-Path $OutputFolder 'cert.pfx'
    $pfxFullFile   = Join-Path $OutputFolder 'fullchain.pfx'

    # download the cert+chain which is was ACMEv2 delivers by default
    # https://tools.ietf.org/html/draft-ietf-acme-acme-12#section-7.4.2
    Invoke-WebRequest $CertUrl -OutFile $fullchainFile

    # split it into individual PEMs
    $pems = Split-PemChain $fullchainFile

    # write the lone cert
    Export-Pem $pems[0] $certFile

    # write the chain
    Export-Pem ($pems[1..($pems.Count-1)] | ForEach-Object {$_}) $chainFile

    # write the cert-only pfx
    Export-CertPfx $certFile $keyFile $pfxFile -FriendlyName $FriendlyName

    # write the full chain pfx
    Export-CertPfx $certFile $keyFile $pfxFullFile -ChainFile $chainFile -FriendlyName $FriendlyName

}
