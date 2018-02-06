## Can't use EC Keys on PowerShell Core

In .NET Core 2.0 which is what is distributed with PowerShell Core 6, the [`ECDsaOpenSsl`](https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.ecdsaopenssl) implementation is missing the `SignData` method which means we can't sign stuff using EC-based keys on non-Windows platforms. 

Additionally, `ECDsaCng` in PowerShell Core on Windows has the `SignData` method, but I can't get it to work for some reason. The same code that works in Desktop edition throws an exception in Core, *"Cannot find an overload for "SignData" and the argument count: "1"."*
