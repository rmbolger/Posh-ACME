# How To Use the Zonomi DNS Plugin

This plugin works against the [Zonomi DNS](https://zonomi.com) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

We need to [generate an API key](https://zonomi.com/app/cp/apikeys.jsp).

You will need the "dns key type" API key. Click the the green plus icon to generate a new "dns key type" API key if one is not already displayed.

## Using the Plugin

The only plugin argument you need is the API key created earlier.

```powershell
New-PACertificate test.example.com -DnsPlugin Zonomi -PluginArgs @{ZonomiApiKey='xxxxxxxxxxxxxxxx'}
```