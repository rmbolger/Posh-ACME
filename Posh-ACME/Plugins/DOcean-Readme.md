# How To Use the DOcean DNS Plugin

This plugin works against the [Digital Ocean](https://m.do.co/c/d515942ef761) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: The link above is an affiliate link which reduces my out of pocket cost to maintain this plugin. I'd be most grateful if you use it when signing up for a new account.*

## Setup

You need to create a [Personal Access Token](https://cloud.digitalocean.com/settings/api/tokens) so the plugin can access Digital Ocean's API.

- Click `Generate New Token`
- Name: **Posh-ACME**
- Check the `Write (optional)` box
- Click `Generate Token`
- Copy the resulting token string somewhere safe. There's no way to retrieve it once you leave this page. You would have to delete the old one and create a new one.

## Using the Plugin

The only plugin argument you need is the API token created earlier.

```powershell
New-PACertificate example.com -Plugin DOcean -PluginArgs @{DOToken='xxxxxxxxxxxxxxxx'}
```
