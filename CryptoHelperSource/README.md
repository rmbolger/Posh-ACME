# CryptoHelper

This embedded helper exports `Get-BCSha3Hash`, which computes SHA3-256 of a
UTF-8 string using BouncyCastle and outputs a lowercase hexadecimal digest,
and `Get-BCCertificateIssuer`, which accepts a single PEM-encoded X.509
certificate and outputs its issuer common name(s). Neither command exposes
BouncyCastle types. Posh-ACME imports this module privately and uses its issuer
command in `Get-ChainIssuers` and its SHA3 command as the SOLIDServer plugin's
fallback when native SHA3 is unavailable. Other BouncyCastle call sites are
unchanged.

Run `./build.ps1` from this directory with a .NET SDK that can target `net471`
and `net6.0`. The build restores NuGet packages and publishes the versioned
module into `../Posh-ACME/CryptoHelper` for inclusion with Posh-ACME. It uses the
`BouncyCastle.Cryptography` 2.7.0 package rather than Posh-ACME's 1.8.8.2 DLL.

Windows PowerShell 5.1 loads the `net471` cmdlet directly, without ALC
isolation. PowerShell 7.2+ loads the `net6.0` cmdlet and its published
BouncyCastle dependency in a private, non-collectible ALC. Its loader stays in
the default ALC. Only one copy of this module can be used per process; start
a new process to switch versions or module paths.

From the workspace root, after building:

```powershell
Import-Module ./Posh-ACME/Posh-ACME/Posh-ACME.psd1

pwsh -NoProfile -Command 'Invoke-Pester -Path ./Posh-ACME/CryptoHelperSource/Tests'
powershell.exe -NoProfile -Command 'Invoke-Pester -Path ./Posh-ACME/CryptoHelperSource/Tests'
```

The Pester tests preload Posh-ACME's older BouncyCastle assembly on PowerShell
7 before importing this module, then check that the two copies coexist. They
verify the SHA3-256 digest of `abc`, issuer CNs from Posh-ACME's chain fixture,
that a forced re-import still exposes the cmdlets, and that Posh-ACME calls the
embedded issuer parser. The SOLIDServer test exercises the SHA3 fallback on
Windows PowerShell 5.1. Posh-ACME's own tests cover matching any issuer CN and
falling back to the default chain when there are none.
The `net6.0` target sets a minimum runtime API surface, not a requirement for
users to install the .NET 6 SDK. Verify the published module on each PowerShell
version you plan to support.
