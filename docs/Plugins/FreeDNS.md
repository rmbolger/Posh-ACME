title: FreeDNS

# How To Use the FreeDNS Plugin

This plugin works against [Free DNS](https://freedns.afraid.org/). It is assumed that you have an existing account. Free and [Premium](https://freedns.afraid.org/premium/) accounts are both supported, but there are limitations on Free accounts unless the domain you're using is actually owned by you. There are also limitations on Premium accounts if you do not own the domain you're using.

## Setup

The only setup needed aside from knowing your account credentials is manually adding at least one subdomain/record to the domain you're going to be working against. The plugin grabs a list of available domains from the [Subdomains](https://freedns.afraid.org/subdomain/) page. So anything not showing on that page won't be found by the plugin.

## Limitations

### Free Accounts

Solving a CAPTCHA is required in order to create any records on domains you don't own. This makes it impossible to automate with the plugin. Make sure you own the domains you're working against.

### Free and Premium Accounts

Regardless of your account status, Free DNS does not currently allow you to create records beginning with an underscore (`_`) unless you own the underlying domain you're creating the records on. Because Let's Encrypt DNS challenges require creating a TXT record that starts with `_acme-challenge`, you will be unable to generate a certificate for a Free DNS hosted domain unless you own it.

The only thing you can use a non-owned domain for are [challenge aliases](../Guides/Using-DNS-Challenge-Aliases.md). But due to the CAPTCHA limitation on Free accounts, only Premium accounts can do this. If using challenge aliases, make sure your CNAME points to a record that does *not* start with `_`.

## Using the Plugin

Your account credentials will be used with the `FDCredential` parameter which is a PSCredential object.

!!! warning
    The `FDUsername` and `FDPassword` parameters are deprecated and will be removed in the next major module version. If you are using them, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    FDCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin FreeDNS -PluginArgs $pArgs
```
