# How To Use the UKFast SafeDNS Plugin

This plugin works against the [UKFast](https://ukfast.co.uk/) provider. It is assumed that you have already setup an account and created the zone in SafeDNS you will be working against.

## Setup

Authentication against the UKFast SafeDNS API requires an `API Application Key`, which can be obtained from the [MyUKFast](https://my.ukfast.co.uk/applications/index.php) portal. Additionally the key must be given 'READ/WRITE' permission for the SafeDNS service. 

For further documentation on working with API keys, please visit the [UKFast Developer Centre](https://developers.ukfast.io/getting-started#registering-applications).

## Using the Plugin

The API key will be used with the `UKFastApiKey` parameter. This is a SecureString. 

```powershell
$pArgs = @{UKFastApiKey=(Read-Host "Enter API Key" -AsSecureString)}
New-PACertificate example.com -Plugin UKFast -PluginArgs $pArgs
```
