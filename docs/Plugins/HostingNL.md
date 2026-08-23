title: HostingNL

# HostingNL

This plugin works against the Hosting.nl REST API (`api.hosting.nl`) for accounts hosted with
[Hosting.nl](https://www.hosting.nl/).

## Setup

Log in to the Hosting.nl control panel and navigate to the API settings.

- Click `Generate New API Key`
- Select `Domains Management (Only Read)` and `Domains Management (Only Write)`
- Click `Generate Key`

Store the resulting key value for use with the plugin.

## Using the Plugin

The key value you generated is used with the `HNLToken' parameter as a SecureString value.

```powershell
$pArgs = @{
    HNLToken = (Read-Host 'Hosting.nl API Token' -AsSecureString)
}

New-PACertificate example.com -Plugin HostingNL -PluginArgs $pArgs
```
