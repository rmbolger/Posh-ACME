# How To Use the deSEC DNS Plugin

This plugin works against the [deSEC](https://desec.io/#!/en/product/dnshosting) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

You may already have an API token from your original registration email. If not, go to the [Token Management](https://desec.io/tokens) page and create a new one. The value will only be shown once towards the bottom of the screen. *It is not the ID value in the list of tokens.*

## Using the Plugin

You will need to provide the API token as a SecureString value to `DSToken` or a standard string value to `DSTokenInsecure`. The SecureString version can only be used from Windows or any OS running PowerShell 6.2 or later. `DSTTL` is the TTL of new `TXT` record (optional, defaults to 300 if not provided).

### Windows or PS 6.2+

```powershell
$token = Read-Host "deSEC Token" -AsSecureString
$pArgs = @{ DSToken = $token; DSTTL=3600 }
New-PACertificate example.com -Plugin DeSEC -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{ DSTokenInsecure = 'token-value'; DSTTL=3600 }
New-PACertificate example.com -Plugin DeSEC -PluginArgs $pArgs
```
