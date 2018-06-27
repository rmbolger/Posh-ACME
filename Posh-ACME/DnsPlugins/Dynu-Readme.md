# How To Use the Dynu DNS Plugin

This plugin works against the [Dynu](https://www.dynu.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

**Please note**: You must bring your own domain. It is not possible to set TXT records on the domains provided by Dynu.

## Setup

You will need to retrieve the Client ID and Secret that will be used to update DNS records. You can find these on your [Dynu Control Panel](https://www.dynu.com/en-US/ControlPanel/APICredentials).

## Using the Plugin

You will need the account's Client ID and Secret to be set as `DynuClientID` and `DynuSecret`.

```powershell
$DynuParams = @{DynuClientID='xxxxxxxx'; DynuSecret='xxxxxxxx'}
New-PACertificate '*.test.example.com','test.example.com' -DnsPlugin Dynu -PluginArgs $DynuParams
```
