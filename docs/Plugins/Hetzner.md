title: Hetzner

# How To Use the Hetzner DNS Plugin

This plugin works against the [Hetzner](https://www.hetzner.de/) DNS provider. It is specifically for DNS zones in the legacy DNS Console. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

!!! warning
    The legacy DNS Console is scheduled to be shut down in May 2026. Please migrate your zones to the new Hetzner Console before then and re-configure your certificates to use the new `HetznerCloud` plugin.
    https://www.hetzner.com/news/dns-beta/

## Setup

You will need to generate an API Token if you haven't already done so. Go to [Manage API tokens](https://dns.hetzner.com/settings/api-token) after logging in to the [DNS Console](https://dns.hetzner.comn). Give the token a name and click `Create access token`. Make a note of the token value as you'll need it later and won't be able to retrieve it after this point.

## Using the Plugin

You will need to provide the API Token as a SecureString value to `HetznerToken`.

!!! warning
    The `HetznerTokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    HetznerToken = (Read-Host 'Hetzner Token' -AsSecureString)
}
New-PACertificate example.com -Plugin Hetzner -PluginArgs $pArgs
```
