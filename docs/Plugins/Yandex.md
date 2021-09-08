title: Yandex

# How To Use the Yandex DNS Plugin

This plugin works against the [Yandex DNS](https://connect.yandex.com) provider. It is assumed that you have already setup an account and delegated and confirmed the domain you will be working against.

## Setup

If you haven't done it already, [generate an administrator token](https://pddimp.yandex.ru/api2/admin/get_token) and record it for later. It is also known as a "PDD" admin token.

## Using the Plugin

The PDD admin token is used with the `YDAdminToken` SecureString parameter. Users have reported DNS replication delays of up to 15 minutes. So you may also have to override the default `DNSSleep` parameter with something longer like 1000.

*NOTE: The `YDAdminTokenInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    YDAdminToken = (Read-Host "Yandex token" -AsSecureString)
}
New-PACertificate example.com -Plugin Yandex -PluginArgs $pArgs -DNSSleep 1000
```
