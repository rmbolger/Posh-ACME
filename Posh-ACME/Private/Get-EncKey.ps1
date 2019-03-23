function Get-EncKey {
    [CmdletBinding()]
    param(
        [switch]$PathOnly
    )

    $keyPath = Join-Path (Get-ConfigRoot) "enc-key.txt"
    if ($PathOnly) { return $keyPath }

    # return if there's no file
    if (-not (Test-Path $keyPath -PathType Leaf)) {
        return $null
    }

    $keyEncoded = (Get-Content -Raw $keyPath -Encoding ascii -EA Stop).Trim()

    try {
        $keyBytes = ConvertFrom-Base64Url $keyEncoded -AsByteArray
    } catch {
        Write-Debug "Unable to decode enc-key.txt: $keyEncoded"
        Write-Warning "Unable to decode encryption key"
        # remove the bad file and return nothing
        Remove-Item $keyPath -Force
        return $null
    }

    # Make sure the key has the proper number of bytes
    if ($keyBytes.Count -ne 32) {
        Write-Debug "Decoded key has $($keyBytes.Count) bytes"
        Write-Warning "Encryption key is invalid. Wrong number of bytes."
        # remove the bad file and return nothing
        Remove-Item $keyPath -Force
        return $null
    }

    return $keyBytes
}
