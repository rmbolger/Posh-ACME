# How To Use the DNSimple DNS Plugin

This plugin works against the [DNSimple](https://dnsimple.com/r/c9b80a2f227e49) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: The link above is an affiliate link which reduces my out of pocket cost to maintain this plugin. I'd be most grateful if you use it when signing up for a new account.*

## Setup

First, [login](https://dnsimple.com/login) to your account and then go to `Account` - `API tokens` and click `New access token`. After giving it a name, it will show you the token string. Be sure to save it as you can't look it up if you forget later. You can only generate a new one. Also, make sure it is an **account** token, not a user token.

## Using the Plugin

With your token value, you'll need to set either the `DSToken` or `DSTokenInsecure` parameter. `DSToken` is a [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring) but only currently works properly on Windows. For non-Windows, use `DSTokenInsecure`.

### Windows

```powershell
$token = Read-Host "DNSimple Token" -AsSecureString
New-PACertificate example.com -Plugin DNSimple -PluginArgs @{DSToken=$token}
```

### Non-Windows

```powershell
New-PACertificate example.com -Plugin DNSimple -PluginArgs @{DSTokenInsecure='xxxxxxxxxxxx'}
```
