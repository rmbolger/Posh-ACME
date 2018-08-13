# This function only exists so that we can mock it in Pester tests
function Get-DateTimeOffsetNow {
    [CmdletBinding()]
    param()
    [System.DateTimeOffset]::Now
}
