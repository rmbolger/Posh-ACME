# How To Use the Infomaniak DNS Plugin

This plugin works against the [Infomaniak](https://www.infomaniak.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

You will need to generate an API Token if you haven't already done so. Go to [Manage API tokens](https://manager.infomaniak.com/v3/0/api/dashboard) after logging in to the [Management Console](https://manager.infomaniak.com). Create a new token with the scope `Domain`. Set the expiration time to your preference. Make a note of the token value as you'll need it later and won't be able to retrieve it after this point.

Note: If the token gets invalidated before a renewal is submitted, a new token has to be created and the order has to be updated.

## Using the Plugin

You will need to provide the API Token as a SecureString value to `InfomaniakToken` or a standard string value to `InfomaniakTokenInsecure`. The SecureString version can only be used from Windows or any OS running PowerShell 6.2 or later.

### Windows or PS 6.2+

```powershell
$token = Read-Host "Infomaniak Token" -AsSecureString
$pArgs = @{InfomaniakToken=$token}
New-PACertificate example.com -Plugin Infomaniak -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{InfomaniakTokenInsecure='xxxxxxxxxxxxxxxxxxxxxxxxx'}
New-PACertificate example.com -Plugin Infomaniak -PluginArgs $pArgs
```
