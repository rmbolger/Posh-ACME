function Get-ChainIssuers {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$OrderFolder
    )

    # Go through the list of chainX.cer files and parse the Issuer CN value
    # from each cert in the chain then return it, its associated file path,
    # and an index value that indicates how close it is to being the root.

    $files = Get-ChildItem (Join-Path $OrderFolder 'chain*.cer') -Exclude 'chain.cer'
    $issuers = foreach ($f in $files) {

        $filePath = $f.FullName
        $lines = Get-Content $filePath

        # check how many are in this chain
        $caCount = ($lines | Where-Object { $_ -eq '-----BEGIN CERTIFICATE-----' }).Count

        $certIndex = $caCount - 1
        $iBegin = 0
        $inCert = $false
        for ($i=0; $i -lt $lines.Count; $i++) {
            if ('-----BEGIN CERTIFICATE-----' -eq $lines[$i].Trim()) {
                $iBegin = $i
                $inCert = $true
                continue
            }
            if ($inCert -and '-----END CERTIFICATE-----' -eq $lines[$i].Trim()) {
                $certString = $lines[$iBegin..$i] -join [Environment]::NewLine
                $cert = Import-Pem -InputString $certString
                $issuerCN = $cert.IssuerDN.GetValueList([Org.BouncyCastle.Asn1.X509.X509Name]::CN)
                Write-Debug "Found issuer, $issuerCN, in $filePath"
                [pscustomobject]@{
                    issuer = $issuerCN
                    filePath = $filePath
                    index = $certIndex
                }
                $certIndex--
                continue
            }
        }
    }

    return $issuers
}
