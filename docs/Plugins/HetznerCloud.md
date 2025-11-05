title: HetznerCloud

# How To Use the Hetzner DNS Plugin

This plugin works against the [Hetzner](https://www.hetzner.de/) DNS provider. It is specifically for DNS zones that have been migrated to Hetzner Console from the old DNS Console which uses a different API and tokens. It is assumed that you have already setup an account and created or migrated the DNS zone(s) you will be working against.

## Setup

You will need to generate an API Token if you haven't already done so. Go to the `Security - API tokens` section after logging in to the [HETZNER Console](https://console.hetzner.comn). Give the token a name, select `Read & Write` permissions, and click `Generate API Token`. Make a note of the token value as you'll need it later and won't be able to retrieve it after this point.

## Using the Plugin

You will need to provide the API Token as a SecureString value to `HCToken`.

```powershell
$pArgs = @{
    HCToken = (Read-Host 'Hetzner Token' -AsSecureString)
}
New-PACertificate example.com -Plugin HetznerCloud -PluginArgs $pArgs
```
