title: DNSExit

# How To Use the DNSExit DNS Plugin

This plugin works with the [DNSExit](https://dnsexit.com/) DNS provider. It is assumed that you have already created the DNS zones you will be using in your DNSExit account.

## Setup

Before using the plugin, create a DNS API key in DNSExit:

1. Sign in to your DNSExit account.
2. Open `Settings`.
3. Open `DNS API Key`.
4. Create and copy the API key.

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

### Example With Multiple Zones

```powershell
$pArgs = @{
    DNSExitApiKey = (Read-Host 'DNSExit API Key' -AsSecureString)
    DNSExitDomain = 'example.com','sub.example.com'
    DNSExitTTL = 5
}

New-PACertificate '*.sub.example.com','sub.example.com' -Plugin DNSExit -PluginArgs $pArgs
```

## Known Limitations

- DNSExit's public API docs clearly document JSON `add`, `delete`, and `update` commands, but they do not clearly document a record lookup API.
- DNSExit's public API docs show delete examples by record `name`. They do not clearly document TXT delete-by-value semantics. This means providers may delete all TXT values at a given record name rather than a single specific value.
- TTL values in DNSExit are documented in minutes, not seconds.

## Testing The Plugin

Before requesting a real certificate, test the plugin against a throwaway name in one of your DNSExit zones:

```powershell
$pArgs = @{
    DNSExitApiKey = (Read-Host 'DNSExit API Key' -AsSecureString)
    DNSExitDomain = 'example.com'
}

$acct = Get-PAAccount

Publish-Challenge example.com -Account $acct -Token 'fake-token' -Plugin DNSExit -PluginArgs $pArgs -Verbose
Unpublish-Challenge example.com -Account $acct -Token 'fake-token' -Plugin DNSExit -PluginArgs $pArgs -Verbose
```
