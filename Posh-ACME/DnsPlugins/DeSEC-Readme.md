# How To Use the deSEC DNS Plugin

This plugin works against the [deSEC](https://desec.io/#!/en/product/dnshosting) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

No setup required, just use the the API token from registration email.

## Using the Plugin

The API token will be used with the `DSToken` parameter. We just have to create it as a SecureString first.
`DSTTL` is the TTL of new `TXT` record (optional, defaults to 300 if not provided).

```powershell
# if on Windows
$token = Read-Host "API token" -AsSecureString
New-PACertificate test.example.com -DnsPlugin DeSEC -PluginArgs @{DSToken=$token; DSTTL=3600}
# otherwise
New-PACertificate test.example.com -DnsPlugin DeSEC -PluginArgs @{DSTokenInsecure='yourdesectoken'; DSTTL=3600}
```
