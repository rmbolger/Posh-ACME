title: DMEasy

# How To Use the DMEasy DNS Plugin

This plugin works against the [DNS Made Easy](https://dnsmadeeasy.com/) provider. It is assumed that you already have an account and at least one Managed zone you will be working against.

## Setup

If you haven't done it already, you need to generate API Credentials for your account from the [Account Information](https://dnsmadeeasy.com/account/info) page. You should end up with an `API Key` and `Secret Key` value. These are what we will use with the plugin.

## Using the Plugin

With your API key and secret, you'll need to pass them with the `DMEKey` parameter and the `DMESecret` SecureString parameter.

!!! warning
    The `DMESecuretInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    DMEKey = 'xxxxxxxxxxxx'
    DMESecret = (Read-Host 'DME Secret' -AsSecureString)
}
New-PACertificate example.com -Plugin DMEasy -PluginArgs $pArgs
```
