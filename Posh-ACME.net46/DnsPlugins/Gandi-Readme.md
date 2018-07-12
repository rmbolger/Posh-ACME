# How To Use the Gandi DNS Plugin

This plugin works against the [Gandi](https://www.gandi.net) DNS provider. It is assumed that you have already setup an account and have a registered domain with an associated DNS zone you will be working against.

## Setup

First, login to your [account page](https://account.gandi.net) and go to the `Security` section. There will be an option to generate or regenerate the "API Key for LiveDNS". Do that and make a record the new value.

## Using the Plugin

There are two parameter sets you can use with this plugin. One requires being on Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The other can be used from any OS.

### Windows or PS 6.2+

```powershell
$token = Read-Host "Gandi Token" -AsSecureString
$gParams = @{GandiToken=$token}
New-PACertificate test.example.com -DnsPlugin Gandi -PluginArgs $gParams
```

### Any OS

```powershell
$gParams = @{GandiTokenInsecure='xxxxxxxxxxxxxxxxxxxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin Gandi -PluginArgs $gParams
```
