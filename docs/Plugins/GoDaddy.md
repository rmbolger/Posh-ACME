title: GoDaddy

# How To Use the GoDaddy DNS Plugin

This plugin works against the [GoDaddy](https://www.godaddy.com) domain registrar hosted DNS provider including their Corporate Brandsight provider. It is assumed that you have already setup an account and registered a domain that is using the default Nameservers.

!!! warning
    It has been reported that enabling GoDaddy's Domain Protection feature on a domain silently prevents API modification of TXT records to the domain. The API calls will appear to succeed, but only empty records get created. If you are having trouble with this plugin, please ensure Domain Protection is disabled.

## Setup

We need to [generate an API key](https://developer.godaddy.com/keys) for the production GoDaddy environment.

- Click `Create New API Key`
- Name: **Posh-ACME**
- Environment: **Production**
- Click `Next`
- Copy the resulting key and secret strings somewhere safe. There's no way to retrieve the secret once you leave this page. You would have to delete the old one and create a new one.

Corporate/Brandsight customers will need to contact their account manager or a Super Admin on their account to generate the API key/secret and provide a Customer ID value.

## Using the Plugin

The Key is used with the `GDKey` string parameter and the Secret is used with the `GDSecretSecure` SecureString parameter. Corporate/Brandsight customers will use the Customer ID value with the `GDCustomerId` string parameter.

!!! warning
    The `GDSecret` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

### Consumer example

```powershell
$pArgs = @{
    GDKey = 'xxxxxxxxxxxxxxxx'
    GDSecret = (Read-Host 'Secret' -AsSecureString)
}
New-PACertificate example.com -Plugin GoDaddy -PluginArgs $pArgs
```

### Corporate example

```powershell
$pArgs = @{
    GDKey = 'xxxxxxxxxxxxxxxx'
    GDSecret = (Read-Host 'Secret' -AsSecureString)
    GDCustomerId = 'yyyyyyyyyyyyyyyy'
}
New-PACertificate example.com -Plugin GoDaddy -PluginArgs $pArgs
```
