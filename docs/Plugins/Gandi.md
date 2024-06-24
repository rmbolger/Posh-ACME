title: Gandi

# How To Use the Gandi DNS Plugin

This plugin works against the [Gandi](https://www.gandi.net) DNS provider. It is assumed that you have already setup an account and have a registered domain with an associated DNS zone you will be working against.

## Setup

First, login to your [account page](https://account.gandi.net) and go to the `Authentication Options` section. Down at the bottom in the `Developer access` section, there are options for `Personal Access Token (PAT)` and `API Key (Deprecated)`.

It is no longer recommended to use the API Key option since it has been deprecated. But it should continue to work with the plugin as long as they allow it to. The main benefit over the PAT option is that it doesn't expire.

In the PAT section, click the link for `See my personal access tokens`. Then click the `Create a token` button.

- Select the appropriate organization
- Give it a cosmetic name
- Set the expiration time (1 year is currently the max)
- Choose whether to limit the PAT to a specific set of domains
- Select the option for `Manage domain name technical configurations` which will force the selection of `See and renew domain names`.
- Click `Create`.

Record the token value and set a reminder to create a new PAT before the old one expires.

## Using the Plugin

The Personal Access Token (PAT) is used with the `GandiPAT` SecureString parameter. If you are using the Legacy API Key option, use the `GandiToken` SecureString parameter instead.

!!! warning
    The `GandiTokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to one of the Secure parameter sets.

### Example for Personal Access Token

```powershell
$pArgs = @{
    GandiPAT = (Read-Host "Personal Access Token" -AsSecureString)
}
New-PACertificate example.com -Plugin Gandi -PluginArgs $pArgs
```

### Example for Legacy API Key

```powershell
$pArgs = @{
    GandiToken = (Read-Host "Legacy API Key" -AsSecureString)
}
New-PACertificate example.com -Plugin Gandi -PluginArgs $pArgs
```
