function Export-CertPfx {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$CertFile,
        [Parameter(Mandatory,Position=1)]
        [string]$KeyFile,
        [Parameter(Mandatory,Position=2)]
        [string]$OutputFile,
        [string]$ChainFile,
        [string]$FriendlyName,
        [string]$PfxPass='',
        [switch]$UseModernPfxEncryption,
        [switch]$UsePfxDerEncoding
    )

    $CertFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CertFile)
    $KeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyFile)
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

    $pfxParams = @{
        CertificatePem = [IO.File]::ReadAllText($CertFile)
        PrivateKeyPem = [IO.File]::ReadAllText($KeyFile)
        FriendlyName = $FriendlyName
        Password = $PfxPass
        UseModernPfxEncryption = $UseModernPfxEncryption
        UsePfxDerEncoding = $UsePfxDerEncoding
    }

    if ('ChainFile' -in $PSBoundParameters.Keys) {
        $ChainFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ChainFile)
        $pfxParams.ChainPem = @(
            foreach ($pem in (Split-PemChain -ChainFile $ChainFile)) {
                $pem -join [Environment]::NewLine
            }
        )
    }

    $pfxBytes = New-Pfx @pfxParams
    [IO.File]::WriteAllBytes($OutputFile, $pfxBytes)

}
