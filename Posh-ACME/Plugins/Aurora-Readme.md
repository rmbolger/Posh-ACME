# How To Use the Aurora DNS Plugin

This plugin works against the [PCExtreme](https://pcextreme.nl/) provider, Aurora DNS. It is assumed that you already have an account and at least one Managed zone you will be working against.

## Setup

If you haven't done it already, you need to generate API Credentials for your account from the [DNS - Health Checks Users](https://cp.pcextreme.nl/auroradns/users) page. You should end up with an `API URL`, `Key` and `Secret` value. These are what we will use with the plugin.

## Using the Plugin

With your API key and secret, you'll need to pass them with the `Key` and `Secret` parameter  (insecure) or `Credential` parameter (secure). The Credential parameter only currently works properly on Windows. For non-Windows, use the `Key` and `Secret` parameter.

```powershell
# On Windows, prompt for the credential
$auroraCredential = Get-Credential -Message "Aurora Username:Key / Password:Secret"
$auroraParams = @{ Api='api.auroradns.eu'; Credential=$AuroraCredential }

# On non-Windows, just use a regular string
$auroraParams = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }

# Request the cert
New-PACertificate example.com -Plugin Aurora -PluginArgs $auroraParams
```
