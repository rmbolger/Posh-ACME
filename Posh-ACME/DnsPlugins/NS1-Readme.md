# How To Use the NS1 DNS Plugin

This plugin works against the [NS1](https://ns1.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the [API Keys](https://my.nsone.net/#/account/settings) page and click `Add Key`. Give it an app name like `Posh-ACME` and uncheck all of the permissions except the ones in the DNS section. You can also optionally add IP whitelist entries to further protect the use of the key. When finished, click `Create Key` and then unhide and record the key value for later.

## Using the Plugin

The API key will be used with the `NS1Key` or `NS1KeyInsecure` parameter. The "Insecure" version must be used on non-Windows OSes due to a bug in PowerShell Core relating to SecureString variables.

### Windows

```powershell
$ns1Key = Read-Host -Prompt "API Key" -AsSecureString
New-PACertificate test.example.com -DnsPlugin NS1 -PluginArgs @{NS1Key=$ns1Key}
```

### Non-Windows

```powershell
New-PACertificate test.example.com -DnsPlugin NS1 -PluginArgs @{NS1KeyInsecure='xxxxxxxxxxxx'}
```
