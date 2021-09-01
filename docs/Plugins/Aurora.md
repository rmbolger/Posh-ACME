title: Aurora

# How To Use the Aurora DNS Plugin

This plugin works against the [PCExtreme](https://pcextreme.nl/) provider, Aurora DNS. It is assumed that you already have an account and at least one Managed zone you will be working against.

## Setup

If you haven't done it already, you need to generate API Credentials for your account from the [DNS - Health Checks Users](https://cp.pcextreme.nl/auroradns/users) page. When you open the user details, you should be provided with an `API URL`, `Key` and `Secret` value. These are what we will use with the plugin.

## Using the Plugin

The API Key and Secret are passed as the username and password in a PSCredential object to the `AuroraCredential` parameter.

There is also an optional `AuroraApi` parameter for the hostname provided in API URL which defaults to `api.auroradns.eu`. So if your API URL is the same, you can ignore that parameter.

```powershell
$cred = Get-Credential -Message "Aurora Username:Key / Password:Secret"
$pArgs = @{
    AuroraCredential = $cred
}
New-PACertificate example.com -Plugin Aurora -PluginArgs $pArgs
```
