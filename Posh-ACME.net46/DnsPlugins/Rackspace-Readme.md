# How To Use the Rackspace DNS Plugin

This plugin works against the [Rackspace Cloud DNS](https://www.rackspace.com/cloud/dns) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the Profile page for your account and record the `Rackspace API Key` value from the Security section. You'll also need your account username.

## Using the Plugin

There are two parameter sets you can use with this plugin. One requires being on Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The other can be used from any OS.

### Windows or PS 6.2+

```powershell
$rsKey = Read-Host "API Key" -AsSecureString
$rsParams = @{RSUsername='myusername';RSApiKey=$rsKey}
New-PACertificate test.example.com -DnsPlugin Rackspace -PluginArgs $rsParams
```

### Any OS

```powershell
$rsParams = @{RSUsername='myusername';RSApiKeyInsecure='xxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin Rackspace -PluginArgs $rsParams
```
