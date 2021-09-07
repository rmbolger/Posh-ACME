title: PointDNS

# How to use the PointDNS Plugin

This plugin works against the [PointDNS](https://pointhq.com) DNS provider. It presumes
that you have already set up an account and created the DNS zone(s) that you are targeting.

## Setup

[Login](https://app.pointhq.com/verify) to your account. Go to `Account` and copy
your API key. Click the key icon if you need to generate a new key.

## Using the Plugin

The `PDUser` parameter should be set to the email address associatedw ith your account. The API key is used with the `PDKey` SecureString parameter.

*NOTE: The `PDKeyInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    PDUser = 'email@example.com'
    PDKey = (Read-Host 'API Key' -AsSecureString)
}
New-PACertificate example.com -Plugin PointDNS -PluginArgs $pArgs
```
