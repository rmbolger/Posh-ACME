## Invoke-WebRequest vs Invoke-RestMethod

The ACME protocol relies on sending things like 'Replay-Nonce' and 'Location' in a response
header rather than part of the response body. `Invoke-RestMethod` in Windows PowerShell 5.1
has no way of capturing response headers. So we need to use `Invoke-WebRequest` instead for
now, grab the nonce from the Headers property, and manually parse the Content property with
`ConvertFrom-Json` rather than having PowerShell do it for us.

Ironically, PowerShell Core 6 has added `-ResponseHeadersVariable` which solves this problem.
But it doesn't really make sense to have completely separate code paths for Core right now.
So we're left hoping they back-port the parameter or sufficient time passes that restricting
people to Core is feasible.
