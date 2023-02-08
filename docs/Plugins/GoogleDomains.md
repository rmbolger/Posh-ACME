title: Google Domains

# How To Use the Google Domains Plugin

This plugin uses the Google Domains ACME challenge API for DNS which is a special purpose API exclusively for DNS based ACME challenges. Note that Google Cloud DNS (see the GCloud plugin) and Google Domains are two distinct products and they use different APIs. You will typically need the Google Domains plugin if you have registered a domain with Google Domains but you are not using Google Cloud for your DNS.

## Setup

With your domain selected in the Google Domains interface, browse to the Security section and choose Create Token under `DNS ACME API`. Copy the secret token value that is generated, this will be used as your access token.

## Using the Plugin

You need to supply your root domain as registered with Google Domains, and your access token.

```powershell
$pArgs = @{
    RootDomain = "example.com"
    AccessToken = (Read-Host "Access Token" -AsSecureString)
}
New-PACertificate example.com -Plugin GoogleDomains -PluginArgs $pArgs
```

As tokens are specific to individual root domains you can optionally instead supply a list of domain/token pairs for use when building multi-domain SAN certificates
```powershell
$pArgs = @{
    DomainTokensInsecure = @{
        "example.com" = "EXAMPLETOKEN=="
    }
}

New-PACertificate www.example.com -Plugin GoogleDomains -PluginArgs $pArgs
```