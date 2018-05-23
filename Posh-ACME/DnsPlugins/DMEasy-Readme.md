# How To Use the DMEasy DNS Plugin

This plugin works against the [DNS Made Easy](https://dnsmadeeasy.com/) provider. It is assumed that you already have an account and at least one Managed zone you will be working against.

**This plugin currently does not work on non-Windows OSes in PowerShell Core. [Click here](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) for details.**

## Setup

If you haven't done it already, you need to generate API Credentials for your account from the [Account Information](https://dnsmadeeasy.com/account/info) page. You should end up with an `API Key` and `Secret Key` value. These are what we will use with the plugin.

## Using the Plugin

The `DMEKey` argument is a normal string variable. But the `DMESecret` is a [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring) which takes a bit more effort to produce.

```powershell
$dmeSecret = Read-Host "DME Secret" -AsSecureString
$dmeParams = @{DMEKey='xxxxxxxxxxxx';DMESecret=$dmeSecret}
New-PACertificate test.example.com -DnsPlugin DMEasy -PluginArgs $dmeParams
```
