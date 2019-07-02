# How To Use the Dreamhost DNS Plugin

This plugin works against the [Dreamhost](https://www.dreamhost.com/) API. It is assumed that you already have web hosting through Dreamhost and are using Dreamhost to manage DNS for your domain(s).

## Setup

We need to generate the API key that will be used to update DNS records. Open the [Web Panel API](https://panel.dreamhost.com/index.cgi) page, and generate a new API key with dns-add_record, and dns-remove_record permissions. It is recommended to name this API key something memorable like "Posh-ACME" by entering this in the "Comment for this key" field. Take note of your new API key.

## Using the Plugin

You will need the previously generated API key to fill the DreamhostApiKey parameter.

```powershell
$DreamhostArgs = @{DreamhostApiKey='xxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin Dreamhost -PluginArgs $DreamhostArgs
```
