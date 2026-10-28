function Export-Pem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [psobject]$InputObject,
        [Parameter(Mandatory,Position=1)]
        [string]$OutputFile
    )

    if ($InputObject -isnot [array] -and $InputObject -isnot [string]) {
        throw "Unsuppored InputObject type"
    }

    # resolve relative paths
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

    # Usually, PEM files are ANSI/ASCII encoded with UNIX line endings which means none of the
    # normal PowerShell stuff for outputting files will work. So we'll use a .NET StreamWriter
    # instead.
    try {
        $sw = [IO.StreamWriter]::new($OutputFile, $false, [Text.Encoding]::ASCII)
        $sw.NewLine = "`n"
        if ($InputObject -is [string]) {
            $sw.Write($InputObject)
        } else {
            foreach ($line in $InputObject) {
                $sw.WriteLine($line)
            }
        }
    } finally { if ($null -ne $sw) { $sw.Close() } }

}
