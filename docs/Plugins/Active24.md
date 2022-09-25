title: Active24

# How To Use the Active24 DNS Plugin

This plugin works against the [Active24](https://active24.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.


## Setup

First, [login](https://customer.active24.com/) to your account. Tokens are placed at  `Customer data edit` page, in `Tokens management`. There is need to type in your password again to manage the tokens.


## Using the Plugin

With your token value, you'll need to set the `Token` SecureString parameter.

!!! warning
    The `TokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    Token = (Read-Host "Active24 Token" -AsSecureString)
}
New-PACertificate example.com -Plugin Active24 -PluginArgs $pArgs
```