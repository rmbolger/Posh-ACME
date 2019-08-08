# How To Use the Domeneshop DNS Plugin

This plugin works against the [Domeneshop](https://domene.shop/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

**Note:** The API is currently (May 2019) a beta ("version 0"). The interface may change before it is released and those changes may break this plugin. Domeneshop recommends not relying on the API for mission critical services until it has been released.

## Setup

We need to retrieve an API token and secret for the account that will be used to update DNS records. [Login](https://www.domeneshop.no/admin?view=api) to Domeneshop using the account that will be used to update DNS.

## Using the Plugin

The API token is specified using the `DomeneshopToken` parameter. The secret is specified either with `DomeneshopSecret` as a [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring) or `DomeneshopSecretInsecure` as a regular string. The SecureString version can only be used on Windows OSes or any OS with PowerShell 6.2 or later. Non-Windows OSes on PowerShell 6.0-6.1 must use the regular string version due to [this issue](https://github.com/PowerShell/PowerShell/issues/1654).

### Windows and/or PS 6.2+ only

```powershell
$pArgs = @{
    DomeneshopToken = 'xxxxxxxxxxxx'
    DomeneshopSecret = (Read-Host "Secret" -AsSecureString)
}
New-PACertificate example.com -DnsPlugin Domeneshop -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{
    DomeneshopToken = 'xxxxxxxxxxxx'
    DomeneshopSecretInsecure = 'yyyyyyyyyyyy'
}
New-PACertificate example.com -DnsPlugin Domeneshop -PluginArgs $pArgs
```
