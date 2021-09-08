title: NameSilo

# How To Use the NameSilo DNS Plugin

This plugin works against the [NameSilo](https://www.namesilo.com) domain registrar. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

For authentication against the NameSilo API, an API key is required. Open the [api manager](https://www.namesilo.com/account/api-manager) page to generate the key. Read the note and understand that you can only retrieve the generated key once. If you have previously generated a key, use that one, otherwise by generating a new key you will invalidate the old key. Accept the API terms of use and click generate. Save the generated key in a secure location.

## Using the Plugin

The API key is used with the `NameSiloKey` SecureString parameter. NameSilo only updates DNS records every 15 minutes. So you should also provide a `-DnsSleep` parameter of 900 or more.

!!! warning
    The `NameSiloKeyInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    NameSiloKey = (Read-Host "NameSilo Key" -AsSecureString)
}
New-PACertificate example.com -Plugin NameSilo -PluginArgs $pArgs -DnsSleep 900
```
