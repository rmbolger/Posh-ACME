title: DeSEC

# How To Use the deSEC DNS Plugin

This plugin works against the [deSEC](https://desec.io/#!/en/product/dnshosting) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

You may already have an API token from your original registration email. If not, go to the [Token Management](https://desec.io/tokens) page and create a new one. The value will only be shown once towards the bottom of the screen. *It is not the ID value in the list of tokens.*

## Using the Plugin

You will need to provide the API token as a SecureString value to `DSCToken`. There is an optional `DSCTTL` parameter to use as the TTL of new `TXT` record. It defaults to 3600 which seems to be the minimum value allowed by the API.

!!! warning
    The `DSToken`, `DSTokenInsecure`, and `DSTTL` parameters have been deprecated because they conflicted with another Posh-ACME plugin. If you are using them, please migrate to the newer parameters as they will be removed in the next major version of the module.

```powershell
$pArgs = @{
    DSCToken = (Read-Host "deSEC Token" -AsSecureString)
}
New-PACertificate example.com -Plugin DeSEC -PluginArgs $pArgs
```
