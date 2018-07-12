# How To Use the Reg.ru Plugin

This plugin works against the [Reg.ru](https://reg.ru) and [Reg.com](https://reg.com) provider.
It is assumed that you have already setup an account and registered the domain you will be working against.

## Setup

API Access is not allowed without adding your client machine's IP or subnet to a whitelist. You may also set a separate API password that is different than your primary account password. But it is not required. Both settings are configured from the API Settings page.

- [Reg.ru API Settings](https://www.reg.ru/user/account/#/settings/api/)
- [Reg.com API Settings](https://www.reg.com/user/account/#/settings/api/)

## Using the Plugin

You will need to provide your account email address and password (or API password) in either the `RegRuCredential` parameter as a PSCredential object or `RegRuLogin` and `RegRuPwdInsecure` parameters as standard string values. The PSCredential option may only be used on Windows or any OS running PowerShell 6.2 or later.

It has been reported that the typical DNS propagation time for this provider is close to 1 hour. So be sure to set the DNSSleep parameter longer than 3600.

### Windows or PS 6.2+

```powershell
# create the plugin args hashtable
$pArgs = @{ RegRuCredential = (Get-Credential) }

# generate the cert
New-PACertificate test.domain.zone -DnsPlugin Regru -DNSSleep 4000 -PluginArgs $pArgs
```

## Any OS

```powershell
# create the plugin args hashtable
$pArgs = @{
    RegRuLogin = 'username'
    RegRuPwdInsecure = 'password'
}

# generate the cert
New-PACertificate test.domain.zone -DnsPlugin Regru -DNSSleep 4000 -PluginArgs $pArgs
```
