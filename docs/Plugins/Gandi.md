title: Gandi

# How To Use the Gandi DNS Plugin

This plugin works against the [Gandi](https://www.gandi.net) DNS provider. It is assumed that you have already setup an account and have a registered domain with an associated DNS zone you will be working against.

## Setup

First, login to your [account page](https://account.gandi.net) and go to the `Security` section. There will be an option to generate or regenerate the "API Key for LiveDNS". Do that and make a record the new value.

## Using the Plugin

The API key is used with the `GandiToken` SecureString parameter.

*NOTE: The `GandiTokenInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    GandiToken = (Read-Host "Gandi Token" -AsSecureString)
}
New-PACertificate example.com -Plugin Gandi -PluginArgs $pArgs
```
