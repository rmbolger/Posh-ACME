title: WEDOS

# How To Use the WEDOS DNS Plugin

This plugin works against the [WEDOS](https://www.wedos.com/zone/) DNS provider. It is assumed that you have already setup an account and added or registered the DNS domain(s) you will be working against.

## Setup

The WAPI (Web API) needs to be explicitly enabled on your account before you can use it. If you haven't already, follow the [instructions here](https://kb.wedos.com/en/wapi-api-interface/wapi-activation-and-settings/).

First it will have you agree to the ToS. Then double check that the IP address you will be connecting from is in the `Allowed IP addresses` field and the preferred protocol is `JSON`. You'll also need to set a password specifically for API access (which should be different than your primary account password).

## Using the Plugin

You will need to provide your account username/email and API password as a PSCredential object to the `WedosCredential` plugin parameter.

```powershell
$pArgs = @{
    WedosCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin WEDOS -PluginArgs $pArgs
```
