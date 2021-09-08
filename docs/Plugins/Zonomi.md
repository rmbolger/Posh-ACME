title: Zonomi

# How To Use the Zonomi DNS Plugin

This plugin works against the [Zonomi DNS](https://zonomi.com) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: The API Zonomi uses is also used by other providers such as [RimuHosting](https://rimuhosting.com/). This plugin is compatible with those as well.*

## Setup

Generate an API key from the [API Keys](https://zonomi.com/app/cp/apikeys.jsp) page using the "DNS" type. Click the the green plus icon to generate a new key if one is not already displayed.

If you use a different compatible provider, there should be an equivalent control panel page for API Keys available.

## Using the Plugin

The API key is used with the `ZonomiKey` SecureString parameter. Users on other Zonomi compatible providers will also need to supply the API URL for that provider to the `ZonomiApiUrl` parameter.

*NOTE: The `ZonomiApiKey` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

### Using Zonomi

```powershell
$pArgs = @{
    ZonomiKey = (Read-Host 'API Key' -AsSecureString)
}
New-PACertificate example.com -Plugin Zonomi -PluginArgs $pArgs
```

### Using RimuHosting

```powershell
$pArgs = @{
    ZonomiKey = (Read-Host 'API Key' -AsSecureString)
    ZonomiApiUrl = 'https://rimuhosting.com/dns/dyndns.jsp'
}
New-PACertificate example.com -Plugin Zonomi -PluginArgs $pArgs
```
