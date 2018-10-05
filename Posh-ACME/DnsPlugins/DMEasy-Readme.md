# How To Use the DMEasy DNS Plugin

This plugin works against the [DNS Made Easy](https://dnsmadeeasy.com/) provider. It is assumed that you already have an account and at least one Managed zone you will be working against.

## Setup

If you haven't done it already, you need to generate API Credentials for your account from the [Account Information](https://dnsmadeeasy.com/account/info) page. You should end up with an `API Key` and `Secret Key` value. These are what we will use with the plugin.

## Using the Plugin

With your API key and secret, you'll need to pass them with the `DMEKey` parameter and either the `DMESecret` or `DMESecretInsecure` parameter. `DMESecret` is a [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring) but only currently works properly on Windows. For non-Windows, use `DMESecretInsecure`.

```powershell
# On Windows, prompt for the SecureString secret
$dmeSecret = Read-Host -Prompt 'DME Secret' -AsSecureString
$dmeParams = @{ DMEKey='xxxxxxxxxxxx'; DMESecret=$dmeSecret }

# On non-Windows, just use a regular string
$dmeParams = @{ DMEKey='xxxxxxxxxxxx'; DMESecretInsecure='yyyyyyyyyyyy' }

# Request the cert
New-PACertificate test.example.com -DnsPlugin DMEasy -PluginArgs $dmeParams
```
