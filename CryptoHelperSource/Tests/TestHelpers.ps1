function Import-CryptoHelperForTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestRoot
    )

    if ($IsCoreCLR) {
        $existingPath = Join-Path $TestRoot '../../Posh-ACME/lib/BC.Crypto.1.8.8.2-netstandard2.0.dll'
        $existingAssembly = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -eq 'BC.Crypto'
        }
        if (-not $existingAssembly) {
            Add-Type -LiteralPath $existingPath
        }
    }

    $modulePath = Join-Path $TestRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}
