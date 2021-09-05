title: Domeneshop

# How To Use the Domeneshop DNS Plugin

This plugin works against the [Domeneshop](https://domene.shop/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

**Note:** The API is currently (May 2019) a beta ("version 0"). The interface may change before it is released and those changes may break this plugin. Domeneshop recommends not relying on the API for mission critical services until it has been released.

## Setup

We need to retrieve an API token and secret for the account that will be used to update DNS records. [Login](https://www.domeneshop.no/admin?view=api) to Domeneshop using the account that will be used to update DNS.

## Using the Plugin

The API token is specified using the `DomeneshopToken` string parameter. The secret is specified with the `DomeneshopSecret` SecureString parameter.

*NOTE: The `DomeneshopSecretInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    DomeneshopToken = 'xxxxxxxxxxxx'
    DomeneshopSecret = (Read-Host "Secret" -AsSecureString)
}
New-PACertificate example.com -Plugin Domeneshop -PluginArgs $pArgs
```
