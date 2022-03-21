title: Porkbun

# How To Use the Porkbun DNS Plugin

This plugin works with the [Porkbun](https://porkbun.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be using.

## Setup

You will need to generate an API key/secret pair if you haven't already done so. Go to [API Access](https://porkbun.com/account/api) after logging in. Give the key a name and click `Create API Key`. Copy both the key and secret (the name you entered is not needed). Note that you won't be able to retrieve the secret in the future.

For each domain that you'd like to manage with the API, you must ensure that `API Access` is enabled under the [Domain Settings](https://porkbun.com/account/domainsSpeedy) (in the Details dropdown)

## Using the Plugin

You will need to provide the API Key and Secret as `SecureString`s to `PorkbunAPIKey` and `PorkbunSecret` respectively. An example is shown below:

```powershell
$PorkbunArgs = @{
    PorkbunAPIKey = (Read-Host 'Porkbun API Key' -AsSecureString);
    PorkbunSecret = (Read-Host 'Porkbun API Secret' -AsSecureString);
}
New-PACertificate example.com -Plugin Porkbun -PluginArgs $PorkbunArgs
```
