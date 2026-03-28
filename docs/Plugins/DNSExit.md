title: DNSExit

# How To Use the DNSExit DNS Plugin

This plugin works with the [DNSExit](https://dnsexit.com/) DNS provider. It is assumed that you have already created the DNS zones you will be using in your DNSExit account.

## Setup

Before using the plugin, create a DNS API key in DNSExit:

1. Sign in to your DNSExit account.
2. Open `Settings`.
3. Open `DNS API Key`.
4. Click `Generate API Key` if you hadn't previously done that.
5. Copy the API key.

The plugin also requires you to specify the hosted zone or zones using `DNSExitDomain`. This plugin intentionally does not try to auto-discover zones from the provider because DNSExit's public API docs do not clearly document that capability.

## Using the Plugin

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| DNSExitApiKey | SecureString | Yes | The DNSExit DNS API key |
| DNSExitTTL | Integer | No | TXT record TTL in minutes. Defaults to `0` |
| DNSExitApiUri | String | No | DNSExit API endpoint. Defaults to `https://api.dnsexit.com/dns/` |

### Example

```powershell
$pArgs = @{
    DNSExitApiKey = (Read-Host 'DNSExit API Key' -AsSecureString)
}

New-PACertificate example.com -Plugin DNSExit -PluginArgs $pArgs
```

### Example Wildcard

```powershell
$pArgs = @{
    DNSExitApiKey = (Read-Host 'DNSExit API Key' -AsSecureString)
    DNSExitTTL = 5
}

New-PACertificate 'example.com','*.example.com' -UseSerialValidation -Plugin DNSExit -PluginArgs $pArgs
```

## Known Limitations

- The DNSExit API does not allow for selective record deletion by value. So when the plugin tries to delete the TXT record it created, it will delete all values for that FQDN, not just the one it created. For typical `_acme-challenge.example.com` records, this is probably fine, but be wary if you're using it with the `-DnsAlias` parameter
and referencing an FQDN that might have other TXT records that could be deleted such
as the domain apex.
- TTL values in DNSExit are documented in minutes, not seconds.
