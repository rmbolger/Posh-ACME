## Invoke-WebRequest vs Invoke-RestMethod

The ACME protocol relies on sending things like 'Replay-Nonce' and 'Location' in a response header rather than part of the response body. `Invoke-RestMethod` in Windows PowerShell 5.1 has no way of capturing response headers. So we need to use `Invoke-WebRequest` instead for now, grab the nonce from the Headers property, and manually parse the Content property with
`ConvertFrom-Json` rather than having PowerShell do it for us.

Ironically, PowerShell Core 6 has added `-ResponseHeadersVariable` which solves this problem. But it doesn't really make sense to have completely separate code paths for Core right now. So we're left hoping they back-port the parameter or sufficient time passes that restricting people to Core is feasible.

## BouncyCastle Dependency

When I originally started this project, I was really hoping to keep everything pure .NET with no binary library dependencies. When I was initially only working with account keys, it seemed doable. But as I got towards more heavy X509 stuff like generating cert requests, exporting PFXs and generating PEMs, it became apparent that I'd have to start relying on the legacy COM [Certificate Enrollment API](https://msdn.microsoft.com/en-us/library/windows/desktop/aa374863(v=vs.85).aspx) which is a lot harder to deal with and would make the whole project harder to maintain.

I briefly contemplated trying to fill in the gaps by shell'ing out to built-in command line tools like certreq and certutil, but they're just not flexible enough to do what I needed. So I turned to what seems to be the most common free 3rd party crypto library, BouncyCastle. And while it's certainly not perfect (particularly in the documentation department for the c# version), it's good enough for now.

And it does look like the native .NET BCL will be getting better crypto-wise soon. There's already a CertificateRequest class in .NET Core 2.0 which is supposed to also show up in .NET 4.7.2 which is in preview at the moment. So I apologize for adding a 2 MB dependency on what should be a 0.2 MB module. But I'll try to replace it with native class libraries as soon as I can.

P.S. Totally not trying to rag on BouncyCastle here. I can't imaging trying to maintain an open source crypto library, particularly one that works largely the same between two different managed runtimes. I'm hugely grateful to that team. I just wish I didn't have to spend so much time Google'ing for examples and tracing the source in Visual Studio to figure out how to do stuff.
