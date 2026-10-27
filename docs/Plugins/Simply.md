title: Simply

# How To Use the Simply.com DNS Plugin

This plugin works against the [Simply.com](https://www.simply.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

!!! warning
    The provider has requested this plugin be renamed to `SimplyCom`. So a clone was created called `SimplyCom` that should be used instead. This version will be removed from the module in the next major release of the module.

## Setup

Using the Simply.com API requires only an API key, which can be created in the [Control Panel](https://www.simply.com/controlpanel/) under Account, API keys.

## Using the Plugin

The API key is used with the `SimplyAPIKey` SecureString parameter.

!!! warning
    The `SimplyAccount` parameter is no longer used because the API key alone identifies the account. It will be removed in the next major module version.

!!! warning
    The `SimplyAPIKeyInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    SimplyAPIKey = (Read-Host 'Enter Key' -AsSecureString)
}
New-PACertificate example.com -Plugin Simply -PluginArgs $pArgs
```
