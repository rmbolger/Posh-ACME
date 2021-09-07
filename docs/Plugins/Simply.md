title: Simply

# How To Use the Simply.com DNS Plugin

This plugin works against the [Simply.com](https://www.simply.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

Using Simply.com API requires only your account name or account number and API Key which can be found on the [account](https://www.simply.com/en/controlpanel/account/) page.

## Using the Plugin

Your account name/number is used with the `SimplyAccount` parameter. The API key is used with the `SimplyAPIKey` SecureString parameter.

*NOTE: The `SimplyAPIKeyInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    SimplyAccount = 'S123456'
    SimplyAPIKey = (Read-Host 'Enter Key' -AsSecureString)
}
New-PACertificate example.com -Plugin Simply -PluginArgs $pArgs
```
