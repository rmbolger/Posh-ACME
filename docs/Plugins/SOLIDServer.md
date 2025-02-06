title: SOLIDServer

# How To Use the SOLIDServer DNS Plugin

This plugin works against [efficient iP SOLIDserver DDI](https://efficientip.com/products/solidserver-ddi/). It is assumed that the DNS zone(s) you will be working against are already deployed and you have the necessary credentials or API keys to modify them.

## Setup

SOLIDserver supports API access via both your standard username/password and more granularly scoped API tokens. API tokens are recommended because they can reduce the impact of compromised credentials when configured properly.

In the `Administration` section of the UI, go to `Authentication & Security - API tokens`. Here you can generate a new token whose access is restricted to the DNS module and optionally a limited lifetime. When the token is created, be sure to record the Token ID & Secret values. The Secret cannot be recovered after dismissing the confirmation dialog.

You may also need the DNS Server name and/or DNS View name that is hosting your zones. If there is only a single master copy of the zone your records reside in, the Server and View can likely be omitted. But if you have for example, split-horizon zones with an internal and external view, you should specify the view name in your plugin parameters.

!!! warning
    The DNS Server and View names are case-sensitive.

## Using the Plugin

Your username and password are used with the `SolidCredential` parameter as a PSCredential object. For API tokens, use the same parameter but with the Token ID as username and Token Secret as password. For token auth, you must also include the `SolidTokenAuth=$true` switch.

Your SOLIDserver IP address or hostname is used with the `SolidAPIHost` parameter. Certificate validation is enabled by default. If your server is using a self-signed certificate, you will also need to include the `SolidIgnoreCert=$true` switch.

The optional DNS Server and View values are used with `SolidDNSServer` and `SolidView` parameters.

Here's a basic example using standard username and password.

```powershell
$pArgs = @{
    SolidAPIHost = 'mysolid.example.internal'
    SolidCredential = (Get-Credential) # this will prompt for username/password
}
New-PACertificate example.com -Plugin SOLIDServer -PluginArgs $pArgs
```

Here's a slightly more complicated example using API tokens, an explicit DNS view, and disabling cert validation.

```powershell
$pArgs = @{
    SolidAPIHost = 'mysolid.example.internal'
    SolidCredential = (Get-Credential) # this will prompt for username/password
    SolidTokenAuth = $true
    SolidView = 'external'
    SolidIgnoreCert = $true
}
New-PACertificate example.com -Plugin SOLIDServer -PluginArgs $pArgs
