function Split-PemChain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ChainFile
    )

    $PEM_BEGIN = '-----BEGIN *'
    $PEM_END   = '-----END *'

    # resolve relative path
    $ChainFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ChainFile)

    $chainLines = Get-Content $ChainFile

    for ($i=0; $i -lt $chainLines.Count; $i++) {
        if ($chainLines[$i] -like $PEM_BEGIN) {
            $iStart = $i
            continue
        }
        if ($chainLines[$i] -like $PEM_END) {
            $pemLines = $chainLines[$iStart..$i]
            Write-Output @(,$pemLines)
            continue
        }
    }

}
