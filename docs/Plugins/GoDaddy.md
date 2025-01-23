title: GoDaddy

# How To Use the GoDaddy DNS Plugin

This plugin works against the [GoDaddy DNS](https://www.godaddy.com) provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against. 

!!! warning
    From April 2024 GoDaddy have introduced API account limits which prevent DNS API access for customers with less than 10 domains on their account. Existing accounts that don't meet the new requirements will now receive an Access Denied error when communicating with the API.

!!! warning
    It has been reported that enabling GoDaddy's Domain Protection feature on a domain silently prevents API modification of TXT records to the domain. The API calls will appear to succeed, but only empty records get created. If you are having trouble with this plugin, please ensure Domain Protection is disabled.

## Setup

We need to [generate an API key](https://developer.godaddy.com/keys) for the production GoDaddy environment.

- Click `Create New API Key`
- Name: **Posh-ACME**
- Environment: **Production**
- Click `Next`
- Copy the resulting key and secret strings somewhere safe. There's no way to retrieve the secret once you leave this page. You would have to delete the old one and create a new one.

## Using the Plugin

The Key is used with the `GDKey` string parameter and the Secret is used with the `GDSecretSecure` SecureString parameter.

!!! warning
    The `GDSecret` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    GDKey = 'xxxxxxxxxxxxxxxx'
    GDSecret = (Read-Host 'Secret' -AsSecureString)
}
New-PACertificate example.com -Plugin GoDaddy -PluginArgs $pArgs
```
