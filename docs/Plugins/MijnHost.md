title: MijnHost

# How To Use the mijn.host DNS Plugin

This plugin works against the [mijn.host](https://mijn.host) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

You will need to generate an API key if you haven't already done so. Log in to the [mijn.host control panel](https://mijn.host/cp/) and navigate to **API Access** to create a new key. Make a note of the key value as you'll need it later and won't be able to retrieve it after this point.

## Using the Plugin

You will need to provide the API key as a SecureString value to `MijnHostApiKey`.

```powershell
$pArgs = @{
    MijnHostApiKey = (Read-Host -Prompt 'mijn.host API Key' -AsSecureString)
}
New-PACertificate example.com -Plugin MijnHost -PluginArgs $pArgs
```
