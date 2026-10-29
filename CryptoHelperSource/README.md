# CryptoHelper

Posh-ACME uses BouncyCastle for cryptographic operations that are not available through the .NET APIs it supports. Loading BouncyCastle as an ordinary dependency can cause version conflicts when another module loads a different version into the same PowerShell process.

CryptoHelper keeps BouncyCastle-dependent operations behind a small interface that exchanges standard .NET values rather than BouncyCastle objects. On PowerShell 7.2 and later, its private Assembly Load Context (ALC) loads the
helper and its BouncyCastle dependency separately from the default context. This is dependency isolation, not a security boundary. Windows PowerShell 5.1 does not support ALCs, so its helper build loads without that isolation.

## Making Changes

Most Posh-ACME development remains PowerShell-only. The built CryptoHelper module is bundled under `Posh-ACME/Posh-ACME/CryptoHelper`, so you do not need the .NET SDK or need to rebuild CryptoHelper when changing Posh-ACME PowerShell code. Only changes to CryptoHelper's C# source, package references, or target frameworks require installing a .NET SDK and re-building the projects. From the workspace root, run:

```powershell
./Posh-ACME/CryptoHelperSource/build.ps1
```

### SDK Setup

The minimum SDK is .NET SDK `10.0.403`. The `global.json` uses `latestFeature` roll-forward, so later SDK versions within the .NET `10.0.x` line are accepted, while versions below `10.0.403` and SDKs from other major or minor lines are not. If multiple compatible SDKs are installed, the newest compatible SDK is selected. You can check installed SDKs with:

```powershell
dotnet --list-sdks
```

The build script runs SDK resolution from the `CryptoHelperSource` folder, so this SDK requirement applies even when you invoke the script from the workspace root. No separate .NET 4.7.1 or .NET 6 SDK installation is needed: a compatible .NET 10.0 SDK builds the `net471` and `net6.0` targets used for Windows PowerShell 5.1 and PowerShell 7.2 and later.
