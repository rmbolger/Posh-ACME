function Test-ValidKeyLength {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$KeyLength
    )

    # short circuit supported EC keys and common RSA keys
    if ($KeyLength -in 'ec-256','ec-384','2048','4096') {
        return $true
    }

    $errorMessage = "Must be 'ec-256','ec-384' for EC keys or between 2048-4096 (divisible by 128) for RSA keys"

    # everything else should at least be a parseable integer
    try { $len = [int]::Parse($KeyLength) }
    catch {
        throw [Management.Automation.ValidationMetadataException] $errorMessage
    }

    # LE supports 2048-4096
    # Windows claims to support 8-bit increments (mod 128)
    if ($len -lt 2048 -or $len -gt 4096 -or ($len % 128) -ne 0) {
        throw [Management.Automation.ValidationMetadataException] $errorMessage
    }

    return $true
}