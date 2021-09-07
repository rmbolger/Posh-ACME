title: Infomaniak

# How To Use the Infomaniak DNS Plugin

This plugin works against the [Infomaniak](https://www.infomaniak.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

You will need to generate an API Token if you haven't already done so. Go to [Manage API tokens](https://manager.infomaniak.com/v3/0/api/dashboard) after logging in to the [Management Console](https://manager.infomaniak.com). Create a new token with the scope `Domain`. Set the expiration time to your preference. Make a note of the token value as you'll need it later and won't be able to retrieve it after this point.

Note: If the token gets invalidated before a renewal is submitted, a new token has to be created and the order has to be updated.

## Using the Plugin

You will need to provide the API Token as a SecureString value to `InfomaniakToken`.

*NOTE: The `InfomaniakTokenInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    InfomaniakToken = (Read-Host "Infomaniak Token" -AsSecureString)
}
New-PACertificate example.com -Plugin Infomaniak -PluginArgs $pArgs
```
