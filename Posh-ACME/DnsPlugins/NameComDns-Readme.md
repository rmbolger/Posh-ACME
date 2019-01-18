# How To Use the NameComDns DNS Plugin

This plugin works against the [NameComDns](https://www.name.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the [Account Settings](https://www.name.com/account/settings/api) page and create a new API token for your account. 

## Using the Plugin

We need to set `NameComUsername` as the account email address and `NameComPassword` as the API token.

```powershell
$pargs = @{NameComUserName='username'; NameComToken='XXXXXXXXXX'}
New-PACertificate test.example.com -DnsPlugin NameComDns -PluginArgs $pargs
```
