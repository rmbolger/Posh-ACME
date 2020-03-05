# How To Use the Reg.ru Plugin

This plugin works against the [Reg.ru](https://reg.ru) provider. It is assumed that you have already setup an account and registered the domain you will be working against.

## Setup

We need to [allow acces to API from IP or subnet](https://www.reg.ru/user/account/#/settings/api/).

You can set "API" administrator password instead your account password.

## Using the Plugin

The plugin arguments you need is the administrator login and administrator password/API password and registered domain name.

```powershell
New-PACertificate test.domain.zone -DnsPlugin Regru -PluginArgs @{RegRuLogin='user@example.com',RegRuPassword='Your_Account_or_API_password', DomainName='domain.zone'}
```