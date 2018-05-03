# How To Use the DOcean DNS Plugin

This plugin works against the [Digital Ocean](https://www.digitalocean.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

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
New-PACertificate test.example.com -DnsPlugin DOcean -PluginArgs @{DOToken='xxxxxxxxxxxxxxxx'}
```
