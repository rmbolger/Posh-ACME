# How To Use the Yandex DNS Plugin

This plugin works against the [Yandex DNS](https://connect.yandex.com) provider. It is assumed that you have already setup an account and delegated the domain you will be working against.

## Setup

We need to [generate an administrator token](https://pddimp.yandex.ru/api2/admin/get_token).

You will need the "PDD" administrator token.

## Using the Plugin

The plugin arguments you need is the administrator token created earlier and domain name delegated on yandex.

```powershell
New-PACertificate test.domain.zone -DnsPlugin Yandex -PluginArgs @{YandexApiKey='xxxxxxxxxxxxxxxx'; DomainName='domain.zone'} -DnsSleep 1000
```