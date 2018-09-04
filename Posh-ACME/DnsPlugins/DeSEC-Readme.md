# How To Use the deSEC DNS Plugin

This plugin works against the [deSEC](https://desec.io/#!/en/product/dnshosting) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

No setup required, just use the the API token from registration email.

## Using the Plugin

The API token will be used with the `DSToken` parameter. We just have to create it as a SecureString first.
`DSTTL` is the TTL of new `TXT` record.

```powershell
$dsToken = Read-Host "API token" -AsSecureString
New-PACertificate test.example.com -DnsPlugin DeSEC -PluginArgs @{DSToken=$dsToken; DSTTL=3600}
```