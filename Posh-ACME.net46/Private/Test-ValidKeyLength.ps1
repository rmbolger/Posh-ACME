function Test-ValidKeyLength {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$KeyLength,
        [switch]$ThrowOnFail
    )

    # For RSA keys, Windows supports a huge range of key sizes. But LE's current Boulder server only supports
    # between 2048-4096 keys. So we'll limit to that until someone complains.
    # https://msdn.microsoft.com/en-us/library/system.security.cryptography.rsacryptoserviceprovider.keysize(v=vs.110).aspx

    # 2020-09-17: LE is now restricting RSA key sizes to only 2048, 3072, and 4096
    # https://community.letsencrypt.org/t/issuing-for-common-rsa-key-sizes-only/133839

    # For EC keys, LE's current Boulder server only supports P-256 and P-384, but we'll
    # also allow P-521 for other CAs or when Boulder supports it eventually.

    # short circuit supported EC keys and common RSA keys
    if ($KeyLength -in 'ec-256','ec-384','ec-521','2048','3072','4096') {
        return $true
    }

    $errorMessage = "Must be 'ec-256','ec-384','ec-521' for EC keys or between 2048-4096 (divisible by 128) for RSA keys"

    # everything else should at least be a parseable integer
    try { $len = [int]::Parse($KeyLength) }
    catch {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] $errorMessage
        }
        return $false
    }

    # LE supports 2048-4096
    # Windows claims to support 8-bit increments (mod 128)
    if ($len -lt 2048 -or $len -gt 4096 -or ($len % 128) -ne 0) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] $errorMessage
        }
        return $false
    }

    return $true
}
