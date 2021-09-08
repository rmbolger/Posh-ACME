title: Selectel

# How To Use the Selectel DNS Plugin

This plugin works against the [Selectel](https://selectel.ru/) provider. It is assumed that you have already setup an account and delegated the domain you will be working against.

## Setup

If you haven't done it already, [generate API key](https://my.selectel.ru/profile/apikeys) and record it for later.

## Using the Plugin

The API Key is used with the `SelectelAdminToken` SecureString parameter.

!!! warning
    The `SelectelAdminTokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    SelectelAdminToken = (Read-Host 'API key' -AsSecureString)
}
New-PACertificate example.com -Plugin Selectel -PluginArgs $pArgs
```
