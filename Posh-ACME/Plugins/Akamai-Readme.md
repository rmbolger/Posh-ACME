# How To Use the Akamai Plugin

This plugin works against the [Akamai Edge DNS](https://www.akamai.com/uk/en/products/security/edge-dns.jsp) provider (formerly known as Fast DNS). It is assumed that you already have an account and one or more primary zones hosted.

## Setup

You will need a set of tokens associated with what Akamai calls an "API Client". If you are a Control Center administrator, you should be able to create this for yourself in the [Identity Management](https://control.akamai.com/apps/identity-management/) section using the instructions [here](https://developer.akamai.com/api/getting-started#createanapiclient). You will need Read/Write access to DNS Zones and Records.

The end of this process should generate a set of four values: `host`, `client_token`, `client_secret`, and `access_token`. If you are not the Control Center administrator, your administrator should be able to provide these values to you after creating an API client on your behalf.

Depending on how you want to use the plugin, you can either [add the values to a `.edgerc` file](https://developer.akamai.com/api/getting-started#addcredentialtoedgercfile) and reference that file path with the plugin or just reference the values directly. Details on those options are provided below.

## Using the Plugin

Akamai is one of the few DNS providers with an API to check whether changes have propagated to the authoritative nameservers for your zones and this plugin will use it automatically. What this means is that if all of the names in your certificate are using the Akamai plugin, you may want to decrease the default `DNSSleep` parameter from 120 seconds down to something small like 10 seconds because the changes should be propagated by the time the sleep timer would normally start. The examples below will demonstrate.

If your API client values are stored in a `.edgerc` file, you can use the `AKUseEdgeRC` parameter rather than specifying all the values explicitly. Use the `AKEdgeRCFile` and `AKEdgeRCSection` parameters if your file is not in the default `~\.edgerc` location or the `[default]` section. Make sure the user who will be running the commands has read access to this file.

### .edgerc Options

```powershell
# default location and section
New-PACertificate example.com -Plugin Akamai -PluginArgs @{AKUseEdgeRC=$true} -DNSSleep 10
```

```powershell
# alternate location and section
$pArgs = @{AKUseEdgeRC=$true; AKEdgeRCFile='C:\ProgramData\.edgerc'; AKEdgeRCSection='poshacme' }
New-PACertificate example.com -Plugin Akamai -PluginArgs $pArgs -DNSSleep 10
```

There are also two parameter sets you can use to specify the values directly. They differ only in how you supply the client secret value. Both require `AKHost`, `AKClientToken`, and `AKAccessToken` as string values. The first uses `AKClientSecret` as a SecureString value and can only be used from Windows or any OS with PowerShell 6.2 or later. The second uses `AKClientSecretInsecure` as a normal string value.

### Windows or PS 6.2+

```powershell
$secret = Read-Host "Client Secret" -AsSecureString
$pArgs = @{
    AKHost = 'myhost.akamaiapis.net'
    AKClientToken = 'xxxxxx'
    AKClientSecret = $secret
    AKAccessToken = 'xxxxxx'
}
New-PACertificate example.com -Plugin Akamai -PluginArgs $pArgs -DNSSleep 10
```

### Any OS

```powershell
$pArgs = @{
    AKHost = 'myhost.akamaiapis.net'
    AKClientToken = 'xxxxxx'
    AKClientSecretInsecure = 'xxxxxx'
    AKAccessToken = 'xxxxxx'
}
New-PACertificate example.com -Plugin Akamai -PluginArgs $pArgs -DNSSleep 10
```
