title: IONOS

# How To Use the IONOS DNS Plugin

This plugin works against the [IONOS.de](https://www.ionos.de/)/[IONOS.com](https://www.ionos.com/) DNS provider. It is assumed that you have already setup an account and one or more domains you will be working against.

## Setup

You will need to generate an API Token if you haven't already done so. Follow the guide provided by IONOS [here (DE)](https://developer.hosting.ionos.de/docs/getstarted) or [here (EN)](https://developer.hosting.ionos.com/docs/getstarted).

## Using the Plugin

You will need to provide the API Public Prefix to `IONOSKeyPrefix` and
the API Secret to `IONOSKeySecret`.

```powershell
$pArgs = @{
	IONOSKeyPrefix = (Read-Host 'API Public Prefix')
	IONOSKeySecret = (Read-Host 'API Secret' -AsSecureString)
}
	
New-PACertificate example.com -Plugin IONOS -PluginArgs $pArgs
```
