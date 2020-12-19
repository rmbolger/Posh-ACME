function Test-WinOnly {
    [CmdletBinding()]
    param(
        [switch]$ThrowOnFail
    )

    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        return $true
    } else {
        if ($ThrowOnFail) {
            $errorMessage = "Only supported on Windows platforms."
            throw [Management.Automation.ValidationMetadataException]$errorMessage
        }
        return $false
    }

}
