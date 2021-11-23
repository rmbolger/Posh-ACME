title: EasyDNS

# How To Use the EasyDNS Plugin

This plugin works against the [EasyDNS](https://www.easydns.com) provider. It is assumed that you have already setup an account with a domain registered.

!!! warning
    The EasyDNS REST API is currently (August 2019) in BETA status and has been for quite a while. Beta APIs may change prior to release and potentially break this plugin. Please don't rely on it for mission critical things.

# Setup

Documentation, including signup instructions, is available at http://docs.sandbox.rest.easydns.net/. When you first receive an API Token and Key, they will be for the sandbox environment, not the live environment. In the sandbox environment, publishing and unpublishing challenge records will work but they will not be hosted as public DNS records and thus can't be used to get a certificate. To move to the live environment, you will need to email the API support team with the request.

## Using the Plugin

The API Token is used with the `EDToken` string parameter. The API Key is used with the `EDKeySecure` SecureString parameter. If you are testing against the sandbox environment, you must also include `EDUseSandbox = $true`.

!!! warning
    The `EDKey` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    EDToken = 'xxxxxxxxxxxxxxxx'
    EDKeySecure = (Read-Host 'Key' -AsSecureString)
}
New-PACertificate example.com -Plugin EasyDNS -PluginArgs $pArgs
```
