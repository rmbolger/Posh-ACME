# How To Use the NameSilo DNS Plugin

This plugin works against the [NameSilo](https://www.namesilo.com) domain registrar. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

For authentication against the NameSilo API, an API key is required. Open the [api manager](https://www.namesilo.com/account/api-manager) page to generate the key. Read the note and understand that you can only retrieve the generated key once. If you have previously generated a key, use that one, otherwise by generating a new key you will invalidate the old key. Accept the API terms of use and click generate. Save the generated key in a secure location.

## Using the Plugin

Provide the `NameSiloApiKey` parameter with the saved API key. Note that NameSilo only updates DNS records every 15 minutes. So try with a `-DnsSleep` setting of 900 or more.

```powershell
$pArgs = @{ NameSiloApiKey='xxxxxxxx' }
New-PACertificate example.com -DnsPlugin NameSilo -PluginArgs $pArgs -DnsSleep 900
```
