title: DuckDNS

# How To Use the DuckDNS Plugin

This plugin works against the [Duck DNS](https://www.duckdns.org/) provider. It is assumed that you have already setup an account and created the domain(s) you will be working against.

## Setup

Look for a `token` value listed on the Duck DNS homepage after you login. You'll need to supply this value as one of the plugin parameters. You will also need the domain subname for each domain that matches one of the names in the certificate you request.

So if you're requesting a cert for `www.mydomain.duckdns.org` and `www.myotherdomain.duckdns.org`, you would need both `mydomain` and `myotherdomain`.

## Using the Plugin

Duck DNS has a rather annoying limitation that there can only ever be a single TXT record associated with all domains on your account. This means that if you request a certificate with multiple names, each name must be validated separately instead of just creating all of the TXT records at once and validating them together. This can make the entire process take a lot longer depending on how many names are in the certificate. In order for Posh-ACME to process the validations in serial rather than parallel, you must specify the `UseSerialValidation` switch in your call to `New-PACertificate`.

Your API token is specified using the `DuckToken` SecureString parameter. You also need to specify the domain subnames using the `DuckDomain` parameter.

*NOTE: The `DuckTokenInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{
    DuckToken = (Read-Host -Prompt "Token" -AsSecureString)
    DuckDomain = 'mydomain1'
}
$certNames = 'mydomain1.duckdns.org','www.mydomain1.duckdns.org'
New-PACertificate $certNames -UseSerialValidation -Plugin DuckDNS -PluginArgs $pArgs
```
