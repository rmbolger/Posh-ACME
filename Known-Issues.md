## Can't use EC256 on Linux/Mac

The `ECDsa` implementation for non-Windows platforms utilizes [ECDsaOpenSsl](https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.ecdsaopenssl). As of .NET Core 2.0 which is what is distributed with PowerShell Core 6, `ECDsaOpenSsl` doesn't contain a `SignData` method.

