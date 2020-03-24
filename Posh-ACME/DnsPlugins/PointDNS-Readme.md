# How to use the PointDNS Plugin

This plugin works against the [PointDNS](https://pointhq.com) DNS provider. It presumes
that you have already set up an account and created the DNS zone(s) that you are targeting.

## Setup

[Login](https://app.pointhq.com/verify) to your account. Go to `Account` and copy
your API key. Click the key icon if you need to generate a new key.

## Using the Plugin

There are two parameter sets you can use with this plugin. The first takes `PDUser` as the email address associated with your account and `PDKey` for your API key as a SecureString object. But it can only be used from Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The second parameter set also takes `PDUser` but uses `PDKeyInsecure` for the API key as a standard String object.

### Windows or PS 6.2+

```powershell
$token = Read-Host "PointDNS Key" -AsSecureString
$pdParams = @{PDUser='email@example.com';PDKey=$token}
New-PACertificate example.com -DnsPlugin PointDNS -PluginArgs $pdParams
```

### Any OS

```powershell
$pdParams = @{PDUser='email@example.com';PDKeyInsecure='xxxxxxxxxxxx'}
New-PACertificate example.com -DnsPlugin PointDNS -PluginArgs $pdParams
```
