# How To Use the GoDaddy DNS Plugin

This plugin works against the [GoDaddy DNS](https://www.godaddy.com) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

We need to [generate an API key](https://developer.godaddy.com/keys) for the production GoDaddy environment.

- Click `Create New API Key`
- Name: **Posh-ACME**
- Environment: **Production**
- Click `Next`
- Copy the resulting key and secret strings somewhere safe. There's no way to retrieve the secret once you leave this page. You would have to delete the old one and create a new one.

## Using the Plugin

The only plugin arguments you need are the API key and API secret created earlier.

```powershell
$pArgs = @{GDKey='xxxxxxxxxxxxxxxx';GDSecret='xxxxxxxxxxxxxxxx'}
New-PACertificate example.com -Plugin GoDaddy -PluginArgs $pArgs
```
