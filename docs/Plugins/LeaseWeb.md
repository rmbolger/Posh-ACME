title: LeaseWeb

# How To Use the LeaseWeb DNS Plugin

This plugin works against the [LeaseWeb](https://www.leaseweb.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

Create your API key from the [Customer Portal](https://secure.leaseweb.com/) and make a note of it for later.

## Using the Plugin

The API key is used with the `LSWApiKey` SecureString parameter.

```powershell
$pArgs = @{
    LSWApiKey = (Read-Host -Prompt 'API Key' -AsSecureString)
}
New-PACertificate example.com -Plugin LeaseWeb -PluginArgs $pArgs
```
