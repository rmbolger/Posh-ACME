# How To Use the Yandex DNS Plugin

This plugin works against the [Yandex DNS](https://connect.yandex.com) provider. It is assumed that you have already setup an account and delegated and confirmed the domain you will be working against.

## Setup

If you haven't done it already, [generate an administrator token](https://pddimp.yandex.ru/api2/admin/get_token) and record it for later. It is also known as a "PDD" admin token.

## Using the Plugin

There are two parameter sets you can use with this plugin. The first uses `YDAdminToken` which is your generated admin token as a SecureString object. But it can only be used from Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The second parameter set uses `YDAdminTokenInsecure` for the token as a standard String object.

*Note: Users have reported DNS replication delays of up to 15 minutes. So you may have to override the default `DNSSleep` parameter with something longer like 1000.*

### Windows or PS 6.2+

```powershell
$token = Read-Host "Yandex token" -AsSecureString
$ydParams = @{YDAdminToken=$token}
New-PACertificate example.com -DnsPlugin Yandex -PluginArgs $ydParams -DNSSleep 1000
```

### Any OS

```powershell
$ydParams = @{YDAdminTokenInsecure='xxxxxxxxxxxx'}
New-PACertificate example.com -DnsPlugin Yandex -PluginArgs $ydParams -DNSSleep 1000
```
