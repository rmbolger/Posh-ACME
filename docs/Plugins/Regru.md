title: Regru

# How To Use the Reg.ru Plugin

This plugin works against the [Reg.ru](https://reg.ru) and [Reg.com](https://reg.com) provider.
It is assumed that you have already setup an account and registered the domain you will be working against.

## Setup

API Access is not allowed without adding your client machine's IP or subnet to a whitelist. You may also set a separate API password that is different than your primary account password. But it is not required. Both settings are configured from the API Settings page.

- [Reg.ru API Settings](https://www.reg.ru/user/account/#/settings/api/)
- [Reg.com API Settings](https://www.reg.com/user/account/#/settings/api/)

## Using the Plugin

Your account username and either the account password or API password are used with the `RegRuCredential` parameter as a PSCredential object. It has been reported that the typical DNS propagation time for this provider is close to 1 hour. So be sure to set the DNSSleep parameter longer than 3600.

!!! warning
    The `RegRuLogin` and `RegRuPwdInsecure` parameters are deprecated and will be removed in the next major module version. If you are using them, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    RegRuCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin Regru -PluginArgs $pArgs -DNSSleep 4000
```
