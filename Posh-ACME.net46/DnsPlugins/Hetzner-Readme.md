# How To Use the Hetzner DNS Plugin

This plugin works against the [Hetzner](https://www.hetzner.de/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

You will need to generate an API Token if you haven't already done so. Go to [Manage API tokens](https://dns.hetzner.com/settings/api-token) after logging in to the [DNS Console](https://dns.hetzner.comn). Give the token a name and click `Create access token`. Make a note of the token value as you'll need it later and won't be able to retrieve it after this point.

## Using the Plugin

You will need to provide the API Token as a SecureString value to `HetznerToken` or a standard string value to `HetznerTokenInsecure`. The SecureString version can only be used from Windows or any OS running PowerShell 6.2 or later.

### Windows or PS 6.2+

```powershell
$token = Read-Host "Hetzner Token" -AsSecureString
$pArgs = @{HetznerToken=$token}
New-PACertificate example.com -DnsPlugin Hetzner -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{HetznerTokenInsecure='xxxxxxxxxxxxxxxxxxxxxxxxx'}
New-PACertificate example.com -DnsPlugin Hetzner -PluginArgs $pArgs
```
