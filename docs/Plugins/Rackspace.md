title: Rackspace

# How To Use the Rackspace DNS Plugin

This plugin works against the [Rackspace Cloud DNS](https://www.rackspace.com/cloud/dns) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the Profile page for your account and record the `Rackspace API Key` value from the Security section. You'll also need your account username.

## Using the Plugin

Your account username is used with the `RSUsername` paraemter. The API key is used with the `RSApiKey` SecureString parameter.

!!! warning
    The `RSApiKeyInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    RSUsername = 'myusername'
    RSApiKey = (Read-Host "API Key" -AsSecureString)
}
New-PACertificate example.com -Plugin Rackspace -PluginArgs $pArgs
```
