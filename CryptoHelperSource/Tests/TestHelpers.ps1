function Import-CryptoHelperForTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestRoot
    )

    $modulePath = Join-Path $TestRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}
