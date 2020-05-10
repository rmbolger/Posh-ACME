# How To Use the Domain Offensive DNS Plugin

This plugin works against the [Domain Offensive](https://www.do.de/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

We need to retrieve an secret API token for the account that will be used to update DNS records. Further information can ba found at [the (german) developer docs.](https://www.do.de/wiki/LetsEncrypt_-_Entwickler).

## Using the Plugin

Your personal API token is specified using the `Token` parameter.

```powershell
$pArgs = @{
    Token = '1md6xRcUCTrB58kbpwAH'
}
New-PACertificate example.com -DnsPlugin DomainOffensive -PluginArgs $pArgs
```
