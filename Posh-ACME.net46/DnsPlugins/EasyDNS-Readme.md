# How To Use the EasyDNS Plugin

This plugin works against the [EasyDNS](https://www.easydns.com) provider. It is assumed that you have already setup an account with a domain registered.

**Note:** The EasyDNS REST API is currently (August 2019) in BETA status and has been for quite a while. Beta APIs may change prior to release and potentially break this plugin. Please don't rely on it for mission critical things.

# Setup

Documentation, including signup instructions, is available at http://docs.sandbox.rest.easydns.net/. When you first receive an API Token and Key, they will be for the sandbox environment, not the live environment. In the sandbox environment, publishing and unpublishing challenge records will work but they will not be hosted as public DNS records and thus can't be used to get a certificate. To move to the live environment, you will need to email the API support team with the request.

## Using the Plugin

The API Token and Key are associated with the `EDToken` and `EDKey` parameters. If you are testing against the sandbox environment, you must also include `EDUseSandbox = $true`.

```powershell
$pArgs = @{ EDToken='xxxxxxxxxxxxxxxx'; EDKey='xxxxxxxxxxxxxxxx' }
New-PACertificate example.com -DnsPlugin EasyDNS -PluginArgs $pArgs
```
