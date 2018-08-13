# How To Use the DNSimple DNS Plugin

This plugin works against the [DNSimple](https://dnsimple.com/r/c9b80a2f227e49) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: The link above is an affiliate link which reduces my out of pocket cost to maintain this plugin. I'd be most grateful if you use it when signing up for a new account.*

## Setup

First, [login](https://dnsimple.com/login) to your account and then go to `Account` - `API tokens` and click `New access token`. After giving it a name, it will show you the token string. Be sure to save it as you can't look it up if you forget later. You can only generate a new one. Also, make sure it is an **account** token, not a user token.

## Using the Plugin

All you have to do is read in the token value as a secure string and then use it with the `DSToken` parameter.

```powershell
$token = Read-Host "DNSimple Token" -AsSecureString
New-PACertificate test.example.com -DnsPlugin DNSimple -PluginArgs @{DSToken=$token}
```
