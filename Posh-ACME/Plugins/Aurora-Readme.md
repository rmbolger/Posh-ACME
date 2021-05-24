# How To Use the Aurora DNS Plugin

This plugin works against the [PCExtreme](https://pcextreme.nl/) provider, Aurora DNS. It is assumed that you already have an account and at least one Managed zone you will be working against.

## Setup

If you haven't done it already, you need to generate API Credentials for your account from the [DNS - Health Checks Users](https://cp.pcextreme.nl/auroradns/users) page. You should end up with an `API URL`, `Key` and `Secret` value. These are what we will use with the plugin.

## Using the Plugin

With your API key and secret, you'll need to pass them with the `Credential` parameter.

```powershell
# Prompt for the credential
$auroraCredential = Get-Credential -Message "Aurora Username:Key / Password:Secret"
$auroraParams = @{ ApiAurora='api.auroradns.eu'; CredentialAurora=$auroraCredential }

# Or entering the key and secret
$auroraParams = @{ ApiAurora='api.auroradns.eu'; CredentialAurora=$((New-Object PSCredential 'KEYKEYKEY',$(ConvertTo-SecureString -String 'SECRETSECRETSECRET' -AsPlainText -Force))) }

# Request the cert
New-PACertificate example.com -Plugin Aurora -PluginArgs $auroraParams
```
