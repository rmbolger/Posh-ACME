$ErrorActionPreference = 'Stop'

Push-Location $PSScriptRoot
try {
    dotnet --version
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not resolve the .NET SDK specified in global.json. Install the required SDK and retry.'
    }

    $project = Join-Path $PSScriptRoot 'src/CryptoHelper/CryptoHelper.csproj'
    $module = Join-Path $PSScriptRoot '../Posh-ACME/CryptoHelper'
    New-Item -ItemType Directory -Path $module -Force | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'module/*') $module -Force

    foreach ($framework in 'net471', 'net6.0') {
        dotnet publish $project --configuration Release --framework $framework --output (Join-Path $module "bin/$framework")
        if ($LASTEXITCODE) { throw "Publish failed for $framework" }
    }
}
finally {
    Pop-Location
}
