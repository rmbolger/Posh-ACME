# How To Use the WebSelfHost Plugin

This is an HTTP challenge plugin that works by temporarily running an HTTP listener to directly respond to challenge requests from the ACME server. It is commonly used when your certificate will not be used with an existing web server or the server is not listening on port 80. It can also be used with an existing web server if you are willing to temporarily stop the server during the certificate issuance process, but this requires additional scripting. The plugin will not automatically stop and restart the other web server.


## Setup

### Windows Only Prerequisites

When running on Windows, the HttpListener class depends on a kernel mode web server called http.sys. Because it's a system-level service, non-administrator users can't use it without an explicit URL reservation that gives them permission. Open an elevated PowerShell session and run the following to see the current list of URL reservations.

```
netsh http show urlacl
```

Modern Windows versions will have a bunch of these even in a default install for various system components and services. We need to add one that matches what the plugin will be trying to use. By default, it will use `http://+:80/.well-known/acme-challenge/`. The easiest thing to do is create the reservation and give permissions to "Everyone". It's perfectly reasonable to only grant permissions to the user or group who will need it as well. But you will need to [adjust the command line](https://docs.microsoft.com/en-us/windows/win32/http/add-urlacl) appropriately with the target user/group instead of an sddl string.

```
netsh http add urlacl url=http://+:80/.well-known/acme-challenge/ sddl=D:(A;;GX;;;S-1-1-0)
```

If you will be running the listener on an alternate port, make sure your reservation also uses the alternate port. Also keep in mind that the ACME validation server will always request challenges on port 80. So if you're using an alternate port, make sure there's an appropriate port forward if it's behind NAT or an HTTP redirect if another server is in front of it.

### Additional Considerations

Regardless of the underlying OS, you need to make sure the listener won't conflict with other software running on the system. If port 80 is in use, you will need to run the listener on an alternate port. But keep in mind, the ACME challenge validations must be served from port 80 on the internet-facing side of things. Often, there will be port forwarding or a reverse proxy in place that maps the internet-facing port 80 to an internal alternate port.


## Using the Plugin

No plugin args are required if you will be using the default port 80 and 120 second timeout. Otherwise, you may use `WSHPort` and `WSHTimeout` respectively.

### Default functionality

```powershell
New-PACertificate example.com -Plugin WebSelfHost -PluginArgs @{}
```

## Non-standard port

```powershell
$pArgs = @{
    WSHPort = 8000
}
New-PACertificate example.com -Plugin WebSelfHost -PluginArgs $pArgs
```
