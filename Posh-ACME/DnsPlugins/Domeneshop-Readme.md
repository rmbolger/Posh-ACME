# How To Use the Domeneshop DNS Plugin

This plugin works against the [Domeneshop](https://domene.shop/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

We need to retrieve an API token and secret for the account that will be used to update DNS records. [Login](https://www.domeneshop.no/admin?view=api) to Domeneshop using the account that will be used to update DNS.

## Using the Plugin

There are two parameter sets you can use with this plugin. One is intended for Windows OSes while the other is intended for non-Windows until PowerShell Core fixes [this issue](https://github.com/PowerShell/PowerShell/issues/1654). The non-Windows API Key parameter is called `DomeneshopSecretInsecure` because the issue prevents PowerShell from encrypting/decrypting SecureString and PSCredential objects.

### Windows

```powershell
$DomeneshopApiCreds = Get-Credential -Message "Domeneshop DNS API token (user name) and secret (password)"
$Params = @{
    Contact = 'somebody@example.com'
    Domain = '*.example.com','example.com'
    DnsPlugin = 'Domeneshop'
    PluginArgs = @{ DomeneshopToken = $DomeneshopApiCreds.UserName; DomeneshopSecret = $DomeneshopApiCreds.Password }
}
New-PACertificate @Params
```

### Non-Windows

```powershell
$Params = @{
    Contact = 'somebody@example.com'
    Domain = '*.example.com','example.com'
    DnsPlugin = 'Domeneshop'
    PluginArgs = @{ DomeneshopToken = '12345'; DomeneshopSecretInsecure = 'xxxxxxxx' }
}
New-PACertificate @Params
```