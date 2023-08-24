title: HurricaneElectricDyn

# How To Use the HurricaneElectricDyn Plugin

This plugin works against [Hurricane Electric DNS](https://dns.he.net/). It uses HE's DynDNS API instead of web scraping like the normal `HurricaneElectric` plugin. It less risky to use because it doesn't require supplying your HE account username and password. It is also less likely to break over time as a supported API. However, it is also more tedious to setup and use. You should already have an account and created the DNS zone(s) you will be working against.

!!! note
    Hurricane Electric can be configured as a secondary to your primary zones hosted elsewhere. This plugin will not work for secondary zones. You must use a plugin that is able to modify the primary nameservers.

## Setup

Due to limitations in how HE's DynDNS API authentication works, you must pre-create all of the DNS TXT
records that will be necessary for the cert you are requesting. Each record must be created with dynamic DNS enabled and then a key/password either set or generated for that record.

For each DNS name in your certificate, you will need to create a TXT record called `_acme-challenge.<DNS name>` in the zone. So if your domain is `example.com`, and you want to create a certificate for both the domain root and `www.example.com`, you would need two TXT records: `_acme-challenge.example.com` and `_acme-challenge.www.example.com`. Wildcard names such as `*.example.com` should have records created as if the wildcard portion wasn't there like `_acme-challenge.example.com`.

Login to [https://dns.he.net/](https://dns.he.net/) and go into the Edit Zone page for the zone you will be creating records in.

- Click the `New TXT` button
- Add the required `Name` value
- Check the box for `Enable entry for dynamic dns`
- Click `Submit`
- Back in the Zone Edit page, click the icon in the `DDNS` column next to the record
- Set an appropriate password for click the `Generate a key` button to use a randomly generated password
- Click `Submit`

You will need to supply both the record name and DDNS password to the plugin for each record you created.

## Using the Plugin

Your record name(s) and DDNS password(s) are used with the `HEDynCredential` parameter as an array of PSCredential objects. If you only have one name in the cert, you only need to supply one credential.

```powershell
$rootPass = Read-Host 'Root Domain' -AsSecureString
$wwwPass = Read-Host 'www' -AsSecureString

$pArgs = @{
    HEDynCredential = @(
        [pscredential]::new('_acme-challenge.example.com',$rootPass)
        [pscredential]::new('_acme-challenge.www.example.com',$wwwPass)
    )
}
New-PACertificate 'example.com','www.example.com' -Plugin HurricaneElectricDyn -PluginArgs $pArgs
```

If you are getting a wildcard cert that also includes the root domain, you will need to use the `-UseSerialValidation` parameter.

```powershell
$rootPass = Read-Host 'Root Domain' -AsSecureString

$pArgs = @{
    HEDynCredential = [pscredential]::new('_acme-challenge.example.com',$rootPass)
}
New-PACertificate 'example.com','*.example.com' -Plugin HurricaneElectricDyn -PluginArgs $pArgs -UseSerialValidation
```
