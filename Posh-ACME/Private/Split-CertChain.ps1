function Split-CertChain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$FullChainPath,
        [Parameter(Mandatory,Position=1)]
        [string]$OutputCert,
        [Parameter(Mandatory,Position=2)]
        [string]$OutputChain
    )

    # The finalized certificate we pull down from the server is supposed to be a
    # PEM chain that starts with the leaf cert followed by the rest of the chain.
    # We want to split the leaf from the rest of the chain and output two files.

    $CERT_BEGIN = '-----BEGIN CERTIFICATE-----*'
    $CERT_END   = '-----END CERTIFICATE-----*'

    # resolve relative paths
    $FullChainPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FullChainPath)
    $OutputCert = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputCert)
    $OutputChain = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputChain)

    # Usually, PEM files are ANSI/ASCII encoded with UNIX line endings which means none of the
    # normal PowerShell stuff for outputting files will work. So we'll use a .NET StreamWriter
    # instead.
    try {
        $swCert = New-Object IO.StreamWriter($OutputCert, $false, [Text.Encoding]::ASCII)
        $swChain = New-Object IO.StreamWriter($OutputChain, $false, [Text.Encoding]::ASCII)
        $swCert.NewLine = "`n"
        $swChain.NewLine = "`n"

        $startCert = $false; $endCert = $false
        $startChain = $false
        foreach ($line in (Get-Content $FullChainPath)) {

            # skip whitespace
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            # find the first line of the cert
            if (!$startCert) {
                if ($line -like $CERT_BEGIN) {
                    Write-Debug "found first cert start"
                    $startCert = $true
                    $swCert.WriteLine($line)
                }
                continue
            }

            # write the rest of the lines of the cert and watch for the end
            if ($startCert -and !$endCert) {
                $swCert.WriteLine($line)
                if ($line -like $CERT_END) {
                    Write-Debug "found first cert end"
                    $endCert = $true
                }
                continue
            }

            # now we're looking for chain certs
            if (!$startChain) {
                if ($line -like $CERT_BEGIN) {
                    Write-Debug "found chain cert start"
                    $startChain = $true
                    $swChain.WriteLine($line)
                }
                continue
            } else {
                $swChain.WriteLine($line)
                if ($line -like $CERT_END) {
                    Write-Debug "found chain cert end"
                    $startChain = $false
                }
                continue
            }

        }

    } finally {
        if ($swCert -ne $null) { $swCert.Close() }
        if ($swChain -ne $null) { $swChain.Close() }
    }

}
