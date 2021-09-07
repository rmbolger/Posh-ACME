title: NS1

# How To Use the NS1 DNS Plugin

This plugin works against the [NS1](https://ns1.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the [API Keys](https://my.nsone.net/#/account/settings) page and click `Add Key`. Give it an app name like `Posh-ACME` and uncheck all of the permissions except the ones in the DNS section. You can also optionally add IP whitelist entries to further protect the use of the key. When finished, click `Create Key` and then unhide and record the key value for later.

## Using the Plugin

The API key will be used with the `NS1Key` SecureString parameter.

*NOTE: The `NS1KeyInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    NS1Key = (Read-Host -Prompt "API Key" -AsSecureString)
}
New-PACertificate example.com -Plugin NS1 -PluginArgs $pArgs
```
