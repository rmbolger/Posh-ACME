title: InfomaniakV2

# How To Use the InfomaniakV2 DNS Plugin

This plugin works against the [Infomaniak](https://www.infomaniak.com) DNS provider using version 2 of their API. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

!!! note
    This plugin is a replacement for the older [Infomaniak](Infomaniak.md) plugin which uses version 1 of the API. Switching requires a new API token, because the v2 endpoints reject the `Domain` scope the old plugin uses. Existing orders keep working on the v1 plugin until you migrate them. See [Migrating from the v1 plugin](#migrating-from-the-v1-plugin) below.

## Setup

You will need to generate an API Token if you haven't already done so. Go to [Manage API tokens](https://manager.infomaniak.com/v3/0/api/dashboard) after logging in to the [Management Console](https://manager.infomaniak.com). Create a new token with the `dns:read` and `dns:write` scopes. Set the expiration time to your preference. Make a note of the token value as you'll need it later and won't be able to retrieve it after this point.

Those two scopes are all the plugin needs. `dns:read` covers the zone lookup and record listing, `dns:write` covers creating and deleting the challenge record. No other scope is required.

!!! note
    If the token gets invalidated before a renewal is submitted, a new token has to be created and the order has to be updated.

!!! warning
    Infomaniak must be the authoritative DNS provider for the domain. If a domain is registered with Infomaniak but its nameservers point elsewhere, the API still returns a leftover zone holding old records, and the plugin will correctly refuse to use it with an "Unable to find matching zone" error. Use the plugin for whichever provider actually serves the zone instead.

## Using the Plugin

You will need to provide the API Token as a SecureString value to `InfomaniakToken`.

```powershell
$pArgs = @{
    InfomaniakToken = (Read-Host "Infomaniak Token" -AsSecureString)
}
New-PACertificate example.com -Plugin InfomaniakV2 -PluginArgs $pArgs
```

## Migrating from the v1 plugin

The v1 and v2 APIs use different token scopes. A token carrying only the legacy `Domain` scope that the v1 plugin uses is rejected by every v2 endpoint, so you must generate a new token with `dns:read` and `dns:write` before switching. The rejection looks like this:

```json
{"result":"error","error":{"code":"all_scopes","description":"This method require this specific scope: \"dns:read\""}}
```

A token with `dns:read` and `dns:write` also works against the v1 endpoints, so the one new token serves both this plugin and the v1 [Infomaniak](Infomaniak.md) plugin. You don't need to keep the old token around, and you can switch back to v1 if needed.

Because both plugins use the same `InfomaniakToken` parameter name, migrating an existing order only requires changing the plugin name and supplying the new token.

```powershell
$pArgs = @{
    InfomaniakToken = (Read-Host "Infomaniak Token" -AsSecureString)
}
Set-PAOrder example.com -Plugin InfomaniakV2 -PluginArgs $pArgs
```
