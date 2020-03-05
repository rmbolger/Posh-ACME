# How To Use the Reg.ru Plugin

This plugin works against the [Reg.ru](https://reg.ru) provider. It is assumed that you have already setup an account and registered the domain you will be working against.

## Setup

We need to [allow acces to API from IP or subnet](https://www.reg.ru/user/account/#/settings/api/).

You can [set "API" administrator password instead your account password](https://www.reg.ru/user/account/#/settings/api/).

## Using the Plugin

The plugin arguments you need is the administrator login and administrator password/API password and registered domain name.
Also, you should use DNSSleep parameter more than 3600, bacause 1 hour is a minimal allowed ttl value for reg.ru.

```powershell
New-PACertificate test.domain.zone -DnsPlugin Regru -DNSSleep 4000 -PluginArgs @{RegRuLogin='user@example.com',RegRuPassword='Your_Account_or_API_password', DomainName='domain.zone'}
```