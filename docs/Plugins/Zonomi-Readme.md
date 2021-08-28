# How To Use the Zonomi DNS Plugin

This plugin works against the [Zonomi DNS](https://zonomi.com) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: The API Zonomi uses is also used by other providers such as [RimuHosting](https://rimuhosting.com/). This plugin is compatible with those as well.*

## Setup

Generate an API key from the [API Keys](https://zonomi.com/app/cp/apikeys.jsp) page using the "DNS" type. Click the the green plus icon to generate a new key if one is not already displayed.

If you use a different compatible provider, there should be an equivalent control panel page for API Keys available.

## Using the Plugin

For Zonomi users, all you need to supply is the `ZonomiApiKey` parameter.

```powershell
New-PACertificate example.com -Plugin Zonomi -PluginArgs @{ZonomiApiKey='xxxxxxxxxxxxxxxx'}
```

If you use a different compatible provider, you must also supply the `ZonomiApiUrl` parameter. Here is an example using RimuHosting.

```powershell
$pArgs = @{
    ZonomiApiKey = 'xxxxxxxxxxxxxxxx'
    ZonomiApiUrl = 'https://rimuhosting.com/dns/dyndns.jsp'
}
New-PACertificate example.com -Plugin Zonomi -PluginArgs $pArgs
```
