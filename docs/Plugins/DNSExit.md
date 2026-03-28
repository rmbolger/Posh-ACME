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
| DNSExitDomain | String[] | Yes | One or more hosted DNS zones in DNSExit. The deepest matching zone is used for each record |
| DNSExitTTL | Integer | No | TXT record TTL in minutes. Defaults to `0` |
| DNSExitApiUri | String | No | DNSExit API endpoint. Defaults to `https://api.dnsexit.com/dns/` |

### Example

```powershell
$pArgs = @{
    DNSExitApiKey = (Read-Host 'DNSExit API Key' -AsSecureString)
    DNSExitDomain = 'example.com'
}

New-PACertificate example.com -Plugin DNSExit -PluginArgs $pArgs
```

### Example Wildcard

The DNSExit API only allows a single TXT record to exist for a given FQDN at a time. This means that if you request a wildcard cert that is valid for the domain apex and the wildcard domain name, each name must be validated separately instead of just creating both TXT records at once and validating them together. In order for Posh-ACME to process the validations in serial rather than parallel, you must specify the `-UseSerialValidation` switch in your call to New-PACertificate.

```powershell
$pArgs = @{
    DNSExitApiKey = (Read-Host 'DNSExit API Key' -AsSecureString)
    DNSExitDomain = 'example.com'
    DNSExitTTL = 5
}

New-PACertificate 'example.com','*.example.com' -UseSerialValidation -Plugin DNSExit -PluginArgs $pArgs
```

## Known Limitations

- DNSExit's public API docs show delete examples by record `name`. They do not clearly document TXT delete-by-value semantics. This means providers may delete all TXT values at a given record name rather than a single specific value.
- TTL values in DNSExit are documented in minutes, not seconds.
