function Split-PemChain {
    [CmdletBinding(DefaultParameterSetName='FromFile')]
    param(
        [Parameter(ParameterSetName='FromFile',Mandatory,Position=0)]
        [string]$ChainFile,
        [Parameter(ParameterSetName='FromBytes',Mandatory,Position=0)]
        [byte[]]$ChainBytes
    )

    if ('FromFile' -eq $PSCmdlet.ParameterSetName) {
        # resolve relative path
        $ChainFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ChainFile)
        $chainLines = Get-Content $ChainFile
    } else {
        # encode the bytes and split on the newlines
        $chainLines = [Text.Encoding]::ASCII.GetString($ChainBytes).Split("`n")
    }

    $PEM_BEGIN = '-----BEGIN *'
    $PEM_END   = '-----END *'

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
