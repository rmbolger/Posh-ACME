# How To Use the Dynu DNS Plugin

This plugin works against the [Dynu](https://www.dynu.com) DNS provider. It is assumed that you have already setup an account configured at least one DDNS domain to work against.

**Note for Free Plan users**: Dynu imposes [some limitations](https://www.dynu.com/en-US/Membership) on non-paid accounts. The most significant is a limit of 4 DNS records per domain which effectively means you can only create a cert with up to 4 names in it from the same domain (and only if you have no other DNS records counting against your limit). Additionally, if you are using one of Dynu's provided domain names, their official policy (as of 03/2019) is that you can't create TXT records until the domain is 30 days old. *Though currently, that limitation only seems to apply to the web GUI.*

## Setup

You will need to retrieve the Client ID and Secret that will be used to update DNS records. You can find these on your [Dynu Control Panel](https://www.dynu.com/en-US/ControlPanel/APICredentials).

## Using the Plugin

You will need the account's Client ID and Secret to be set as `DynuClientID` and `DynuSecret`.

```powershell
$DynuParams = @{DynuClientID='xxxxxxxx'; DynuSecret='xxxxxxxx'}
New-PACertificate example.com -Plugin Dynu -PluginArgs $DynuParams
```

## "Quota Exception" error

If you get this message it likely means you're on a free account and you've added too many names from the same domain to a certificate. See the note at the top of this guide for details.
