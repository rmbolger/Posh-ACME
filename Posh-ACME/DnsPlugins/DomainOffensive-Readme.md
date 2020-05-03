# How To Use the Domain Offensive DNS Plugin

This plugin works against the [Domain Offensive](https://www.do.de/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

We need to retrieve an secret API token for the account that will be used to update DNS records. Further information can ba found at [the (german) developer docs.](https://www.do.de/wiki/LetsEncrypt_-_Entwickler).

## Using the Plugin

Your personal API token is specified using the generated `Token` parameter.
The fully qualified name for the TXT record can be specified using the `RecordName` parameter.
The value for the TXT record can be specified using the `TxtValue` parameter.

```powershell
$pArgs = @{
    Token = '1md6xRcUCTrB58kbpwAH',
    Domain = '_acme-challenge.site1.example.com',
    TxtValue = 'OVxwaDm7MgN1IRG0eSivJMlepO9CL4X8vKo6Tcns'
}
New-PACertificate example.com -DnsPlugin DomainOffensive -PluginArgs $pArgs
```
