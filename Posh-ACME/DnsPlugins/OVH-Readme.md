# How To Use the OVH DNS Plugin

This plugin works against the [OVH](https://www.ovh.com) DNS provider. It is assumed that you have already setup an account and created the domain(s) you will be working against.

## Setup

OVH has a variety of supported regions each with their own API endpoint and sets of credentials. In order to set things up properly, you must know which region your account is in. The table below lists the available regions, the region code, and a link to create an Application Credential.

Region | Code | API App Creation
--- | --- | ---
OVH Europe | ovh-eu | [Create App](https://eu.api.ovh.com/createApp/)
OVH US | ovh-us | [Create App](https://api.us.ovhcloud.com/createApp/)
OVH North-America | ovh-ca | [Create App](https://ca.api.ovh.com/createApp/)
So you Start Europe | soyoustart-eu | [Create App](https://eu.api.soyoustart.com/createApp/)
So you Start North America | soyoustart-ca | [Create App](https://ca.api.soyoustart.com/createApp/)
Kimsufi Europe | kimsufi-eu | [Create App](https://eu.api.kimsufi.com/createApp/)
Kimsufi North America | kimsufi-ca | [Create App](https://ca.api.kimsufi.com/createApp/)
RunAbove | runabove-ca | [Create App](https://api.runabove.com/createApp/)

*NOTE: Only one OVH region is supported per ACME account. If you have domains in multiple regions that need certificates, please create a separate ACME account for each one.*

### Create Application Credentials

Select the region that matches your account and use the appropriate "Create App" link to create an application credential for your account. Set the App Name and Description to whatever you want and click `Create Keys`. You will be presented with an `Application Key` and `Application Secret` which you should save for later.

### Generate Consumer Key

Now we need to generate a Consumer Key for these App credentials that is associated with a set of permissions on your account. There is a helper function built-into the plugin file that should make this easier to do. But you can skip this if you already know how to generate an appropriate consumer key that has permissions to modify the DNS zones you will be creating certificates against.

Using the appropriate region code from the table above and the Application Key you just created, run the following PowerShell and follow the instructions. It will generate a URL you must open in a browser, verify the requested permissions, **set the Validity to "Unlimited"**, and click `Log In`.

```powershell
Import-Module Posh-ACME
. (Join-Path (Get-Module Posh-ACME).ModuleBase "DnsPlugins\OVH.ps1")
Invoke-OVHSetup -AppKey 'xxxxxxxxxxxx' -OVHRegion 'ovh-eu'
```

After logging in successfully, you should be redirected to a success page on the Posh-ACME wiki. Press Enter in the PowerShell Window to be presented with your Consumer Key value which you should save for later.

## Using the Plugin

The App Key value will be used with the `OVHAppKey` parameter. The App Secret and Consumer Key values will either be used with `OVHAppSecret`/`OVHConsumerKey` or `OVHAppSecretInsecure`/`OVHConsumerKeyInsecure` depending on your Operating System and PowerShell version. The "Insecure" versions are intended for non-Windows OSes running PowerShell 6.1 or earlier which are unable to properly handle SecureString values. Windows OSes and other OSes running PowerShell 6.2 or later may use either set.

### Windows and/or PS 6.2 and later

```powershell
$appSecret = Read-Host -Prompt "App Secret" -AsSecureString
$consumerKey = Read-Host -Prompt "Consumer Key" -AsSecureString
$pArgs = @{
    OVHAppKey = 'xxxxxxxxxxx'
    OVHAppSecret = $appSecret
    OVHConsumerKey = $consumerKey
    OVHRegion = 'ovh-eu'
}
New-PACertificate test.example.com -DnsPlugin OVH -PluginArgs $pArgs
```

### Non-Windows PS 6.1 and earlier

```powershell
$pArgs = @{
    OVHAppKey = 'xxxxxxxxxxxx'
    OVHAppSecretInsecure = 'yyyyyyyyyyyy'
    OVHConsumerKeyInsecure = 'zzzzzzzzzzzz'
    OVHRegion = 'ovh-eu'
}
New-PACertificate test.example.com -DnsPlugin OVH -PluginArgs $pArgs
```
