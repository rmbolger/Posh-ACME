# How To Use the Zilore DNS Plugin

This plugin works against the [Zilore](https://zilore.com/?r=1f752c82378516890a5200006eae8469) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

**Note:** Zilore does not currently offer API access to free accounts. You must be on a paid plan to use this plugin.

## Setup

You will need to retrieve your API key from the [API Settings](https://my.zilore.com/account/api) page.

## Using the Plugin

The API key is specified using the `ZiloreKey` parameter which is a SecureString value.

```powershell
$pArgs = @{
    ZiloreKey = (Read-Host "API Key" -AsSecureString)
}
New-PACertificate example.com -Plugin Zilore -PluginArgs $pArgs
```
