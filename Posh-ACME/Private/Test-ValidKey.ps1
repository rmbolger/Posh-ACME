function Test-ValidKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
        [switch]$ThrowOnFail
    )

    # Key must be RSA or ECDsa type

    if ($Key -isnot [Security.Cryptography.RSA] -and $Key -isnot [Security.Cryptography.ECDsa]) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "Invalid key type."
        }
        return $false
    }

    # For RSA keys, Windows supports a huge range of key sizes. But LE's current Boulder server only supports
    # between 2048-4096 keys. So we'll limit to that until someone complains.
    # https://msdn.microsoft.com/en-us/library/system.security.cryptography.rsacryptoserviceprovider.keysize(v=vs.110).aspx

    if ($Key -is [Security.Cryptography.RSA] -and ($Key.KeySize -lt 2048 -or $Key.KeySize -gt 4096 -or ($Key.KeySize % 128) -ne 0)) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "RSA key size out of range. Must be 2048-4096 (divisible by 128)."
        }
        return $false
    }

    # For EC keys, LE's current Boulder server only supports P-256 and P-384, but may support P-521 in the future.
    # In all testing so far, the KeySize matches the "P-xxxx" curve name. So we'll just use that to test
    # until someone finds a contrary example. The alternative is checking $Key.Key.Algorithm, but that's not currently
    # working against PowerShell Core.

    if ($Key -is [Security.Cryptography.ECDsa] -and $Key.KeySize -notin 256,384) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "EC curve out of range. Must be P-256 or P-384."
        }
        return $false
    }

    return $true
}
