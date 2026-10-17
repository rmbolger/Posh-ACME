# CryptoHelper

Posh-ACME uses BouncyCastle for cryptographic operations that are not available through the .NET APIs it supports. Loading BouncyCastle as an ordinary dependency can cause version conflicts when another module loads a different version into the same PowerShell process.

CryptoHelper keeps BouncyCastle-dependent operations behind a small interface that exchanges standard .NET values rather than BouncyCastle objects. On PowerShell 7.2 and later, its private Assembly Load Context (ALC) loads the
helper and its BouncyCastle dependency separately from the default context. This is dependency isolation, not a security boundary. Windows PowerShell 5.1 does not support ALCs, so its helper build loads without that isolation.

## Developing Posh-ACME

Most Posh-ACME development remains PowerShell-only. The built CryptoHelper module is bundled under `Posh-ACME/Posh-ACME/CryptoHelper`, so you do not need the .NET SDK or need to rebuild CryptoHelper when changing Posh-ACME PowerShell code. From the workspace root, import Posh-ACME and run the relevant tests:

```powershell
Import-Module ./Posh-ACME/Posh-ACME/Posh-ACME.psd1
Invoke-Pester -Path @(
	'./Posh-ACME/Tests/Get-ChainIssuers.Tests.ps1'
	'./Posh-ACME/Tests/Export-PACertFiles.Tests.ps1'
	'./Posh-ACME/Tests/Get-PACertificate.Tests.ps1'
	'./Posh-ACME/Tests/SOLIDServer.Tests.ps1'
	'./Posh-ACME/CryptoHelperSource/Tests'
)
```

## Changing CryptoHelper

Only changes to CryptoHelper's C# source, package references, or target frameworks require installing a .NET SDK and a rebuild. From the workspace root, run:

```powershell
./Posh-ACME/CryptoHelperSource/build.ps1
```

The build targets .NET Framework 4.7.1 for Windows PowerShell 5.1 and .NET 6 for PowerShell 7.2 and later. It publishes the helper into the bundled module folder. A newer .NET SDK can target .NET 6; installing the .NET 6 SDK itself is not required.
