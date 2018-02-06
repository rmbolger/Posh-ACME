## Invoke-WebRequest vs Invoke-RestMethod

The ACME protocol relies on sending the 'Replay-Nonce' value in a response header. 
`Invoke-RestMethod` in Windows PowerShell 5.1 has no way of capturing response headers.
So we need to use `Invoke-WebRequest` instead for now, grab the nonce from the Headers
property, and manually parse the Content property with `ConvertFrom-Json` rather than 
having PowerShell do it for us.

Ironically, PowerShell Core 6 has added `-ResponseHeadersVariable` which solves this problem.
But it doesn't really make sense to have completely separate code paths for Core right now.
So we're left hoping they back-port the parameter or sufficient time passes that restricting
people to Core is feasible.

## No ECDsa.SignData on Core editions

In .NET Core 2.0, the `ECDsaOpenSsl` implementation is missing the `SignData` method which means we can't sign stuff using EC-based keys on non-Windows platforms. 

Additionally, `ECDsaCng` in PowerShell Core on Windows has the `SignData` method, but I can't get it to work for some reason. The same code that works in Desktop edition throws an exception in Core, *"Cannot find an overload for "SignData" and the argument count: "1"."*
