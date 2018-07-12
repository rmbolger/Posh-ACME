# How To Use the Selectel DNS Plugin

This plugin works against the [Selectel](https://selectel.ru/) provider. It is assumed that you have already setup an account and delegated the domain you will be working against.

## Setup

If you haven't done it already, [generate API key](https://my.selectel.ru/profile/apikeys) and record it for later.

## Using the Plugin

There are two parameter sets you can use with this plugin. The first uses `SelectelAdminToken` which is your generated admin token as a SecureString object. But it can only be used from Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The second parameter set uses `SelectelAdminTokenInsecure` for the token as a standard String object.

### Windows or PS 6.2+

```powershell
$token = Read-Host "Selectel API key" -AsSecureString
$StParams = @{SelectelAdminToken=$token}
New-PACertificate example.com -DnsPlugin Selectel -PluginArgs $StParams
```

### Any OS

```powershell
$StParams = @{SelectelAdminTokenInsecure='xxxxxxxxxxxx'}
New-PACertificate example.com -DnsPlugin Selectel -PluginArgs $StParams
```
