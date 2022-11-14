title: Bunny

# How To Use the Bunny.net DNS Plugin

This plugin works against the [Bunny.net](https://bunny.net) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.


## Setup

First, [login](https://panel.bunny.net/) to your account. Your API Key (Access Key) is available under the Account section.

## Using the Plugin

Use your account API Key as the `BunnyAccessKey` SecureString parameter.

```powershell
$pArgs = @{
    BunnyAccessKey = (Read-Host "Bunny Access Key" -AsSecureString)
}
New-PACertificate example.com -Plugin Bunny -PluginArgs $pArgs
```
