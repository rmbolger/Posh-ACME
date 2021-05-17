# How To Use the Registeram DNS Plugin

This plugin works against the [Registeram](https://Registeram.com/) API see: https://my.registeram.com/index.php?/userapi/

It is assumed that you already have the following:

1.  your bearer token base64(username:password)
2.  service_id for your account
3.  domain_id for the specific domain you wish to create Cert for

## Setup

You can easily obtain 2 & 3 above via: curl -k "https://www.registeram.com/ng/api/dns" -u username:password

## Using the Plugin

```powershell
# just use a regular string
$regParams = @{ RegisteramServiceID=1234; RegisteramDomainID=66; RegisteramAuthHash='am9obnNub3c6aXMtYS1kdW1iLWR1ZGU=' }

# Request the cert
New-PACertificate example.com -Plugin Registeram -PluginArgs $regParams
```
