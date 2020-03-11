# How To Use the Reg.ru Plugin

This plugin works against the [Reg.ru](https://reg.ru) provider.
It is assumed that you have already setup an account and registered the domain you will be working against.

## Setup

You need to [allow acces to API from your IP or subnet](https://www.reg.ru/user/account/#/settings/api/).

You can [set "API" administrator password instead your account password](https://www.reg.ru/user/account/#/settings/api/).

## Using the Plugin

The plugin arguments you need is the administrator login and administrator password or API password.
Also, you need to set TTL to 3600 for your zone and use DNSSleep parameter more than 3600 in most cases.
Unfortunately, 1 hour is a minimal value for Reg.ru

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
```powershell
New-PACertificate test.domain.zone -DnsPlugin Regru -DNSSleep 4000 -PluginArgs $pArgs
```
