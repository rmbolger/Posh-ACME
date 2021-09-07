title: HurricaneElectric

# How To Use the HurricaneElectric Plugin

This plugin works against [Hurricane Electric DNS](https://dns.he.net/). It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: Hurricane Electric can be configured as a secondary to your primary zones hosted elsewhere. This plugin will not work for secondary zones. You must use a plugin that is able to modify the primary nameservers.*

## Setup

There's not really any setup aside from knowing your account credentials. Hurricane Electric doesn't currently support an API for manipulating DNS records. So this plugin utilizes web scraping to accomplish the task. That also means it is more likely to break if the site owner ever changes their HTML markup. So be wary of depending on this for critical projects.

## Using the Plugin

Your account credentials will be used with the `HECredential` parameter as a PSCredential object.

*NOTE: The `HEUsername` and `HEPassword` parameters are deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{ HECredential = (Get-Credential) }
New-PACertificate example.com -Plugin HurricaneElectric -PluginArgs $pArgs
```
