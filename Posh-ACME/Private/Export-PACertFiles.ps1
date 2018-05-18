function Export-PACertFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$CertUrl,
        [Parameter(Mandatory,Position=1)]
        [string]$OutputFolder,
        [string]$FriendlyName='',
        [string]$PfxPass=''
    )

    # build output paths
    $certFile      = Join-Path $OutputFolder 'cert.cer'
    $keyFile       = Join-Path $OutputFolder 'cert.key'
    $chainFile     = Join-Path $OutputFolder 'chain.cer'
    $fullchainFile = Join-Path $OutputFolder 'fullchain.cer'
    $pfxFile       = Join-Path $OutputFolder 'cert.pfx'
    $pfxFullFile   = Join-Path $OutputFolder 'fullchain.pfx'

    # download the cert+chain which is what ACMEv2 delivers by default
    # https://tools.ietf.org/html/draft-ietf-acme-acme-12#section-7.4.2
    Invoke-WebRequest $CertUrl -OutFile $fullchainFile @script:UseBasic

    # split it into individual PEMs
    $pems = Split-PemChain $fullchainFile

    # write the lone cert
    Export-Pem $pems[0] $certFile

    # write the chain
    Export-Pem ($pems[1..($pems.Count-1)] | ForEach-Object {$_}) $chainFile

    # write the pfx files
    $pfxParams = @{
        CertFile     = $certFile;
        KeyFile      = $keyFile;
        OutputFile   = $pfxFile;
        FriendlyName = $FriendlyName;
        PfxPass      = $PfxPass;
    }
    Export-CertPfx @pfxParams
    $pfxParams.OutputFile = $pfxFullFile
    Export-CertPfx @pfxParams -ChainFile $chainFile

}
