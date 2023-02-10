title: GoogleDomains

# How To Use the Google Domains Plugin

This plugin is for domains registered with [Google Domains](https://domains.google/) **and** using its native DNS service. Do not confuse it with [Google Cloud DNS](https://cloud.google.com/dns) which should use the [GCloud](GCloud.md) plugin instead.

## Setup

With your domain selected in the Google Domains interface, browse to the Security section and choose Create Token under `DNS ACME API`. Save the secret token value that is generated. You will provide it to the plugin along with the root domain.

## Using the Plugin

To generate a certificate that is comprised of names all within a single domain, you will pass the root domain and the access token as a PSCredential object to the `GDomCredential` parameter where the username is the root domain and the password is the access token.

```powershell
$pArgs = @{
    GDomCredential = Get-Credential -Username example.com
}
New-PACertificate 'example.com','www.example.com' -Plugin GoogleDomains -PluginArgs $pArgs
```

If you are generating a certificate that uses names from multiple domains, make sure you have an access token for each domain and provide an array of PSCredential objects to the `GDomCredential` parameter for each unique domain in your cert.

```powershell
$pArgs = @{
    GDomCredential = @(
        (Get-Credential -Username example.com)
        (Get-Credential -Username example.net)
    )
}
New-PACertificate 'www.example.com','www.example.net' -Plugin GoogleDomains -PluginArgs $pArgs
```
