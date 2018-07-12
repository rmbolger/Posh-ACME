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

Now we need to generate a Consumer Key for these App credentials that is associated with a set of permissions on your account. There are generally three different ways to configure permissions for the Consumer Key. 

- Write access to all DNS zones on your account. This is useful if you want a single instance of Posh-ACME to be able to generate certs for any name in any domain you might host on OVH.
- Write access to only a specific set of DNS zones on your account. This lets you keep some zones inaccessible, but still lets you generate certs for any name within allowed set of domains.
- Write access only to specific pre-created TXT records. This is the most complicated to setup, but also provides the least risk in case the key is compromised.

There is a helper function built-into the plugin file that can make setting up these permissions easier. In order to use it, run the following to add the function to your current PowerShell session. Then follow the instructions in the next section for the option you will be using.

```powershell
Import-Module Posh-ACME
. (Join-Path (Get-Module Posh-ACME).ModuleBase "DnsPlugins\OVH.ps1")
```

#### Write to All Zones

Using the appropriate region code from the table above and the Application Key you previously created, run the following PowerShell and follow the instructions it gives. It will generate a URL you must open in a browser, verify the requested permissions, **set the Validity to "Unlimited"**, and click `Log In`.

```powershell
Invoke-OVHSetup -AppKey 'xxxxxxxxxxxx' -OVHRegion 'ovh-eu'
```

#### Write to Specific Zones

Define the set of zones you wish to grant access to.

```powershell
$zones = 'example.com','example.net','example.org'
```

Using the appropriate region code from the table above and the Application Key you previously created, run the following PowerShell and follow the instructions it gives. It will generate a URL you must open in a browser, verify the requested permissions, **set the Validity to "Unlimited"**, and click `Log In`.

```powershell
Invoke-OVHSetup -AppKey 'xxxxxxxxxxxx' -OVHRegion 'ovh-eu' -Zone $zones
```

#### Write to Specific Records

In order to use this method, you have to pre-create every TXT record the ACME server is going to need in order to validate the names in the certs you will be requesting. For non-wildcard names, prepend `_acme-challenge.` to the name. For wildcard names, replace the `*` with `_acme-challenge`.

For a cert that contains `example.com`, `www.example.com`, and `support.example.com`, you would need to create the following three records.

- Sub-domain: `_acme-challenge` .example.com
- Sub-domain: `_acme-challenge.www` .example.com
- Sub-domain: `_acme-challenge.support` .example.com

For a typical wildcard cert that contains `example.com` and `*.example.com`, you would need to create two copies of the same record.

- Sub-domain: `_acme-challenge` .example.com
- Sub-domain: `_acme-challenge` .example.com

Once your records are created, you need to identify the record ID for each one. Unfortunately, we haven't found an easy way to find these from OVH's web based DNS editor. The closest alternative is the [API Console](https://api.ovh.com/console/). Login and expand the `GET /domain/zone/{zoneName}/record` entry. Add the appropriate record details to lookup and press `Execute`. The result should be one or more record ID numbers.

Using the record ID(s) and associated zone name(s), create an array of permission objects. It should contain a `GET /domain/zone/<zone name>/record*` and `POST /domain/zone/<zone name>/refresh` entry for each domain plus a `PUT /domain/zone/<zone name>/record/<id>` entry for each record. So the typical wildcard cert example might look like this:

```powershell
$rules = @(
    @{ method = 'GET';  path = '/domain/zone/example.com/record*' }
    @{ method = 'POST'; path = '/domain/zone/example.com/refresh' }
    @{ method = 'PUT';  path = '/domain/zone/example.com/record/1111111111' }
    @{ method = 'PUT';  path = '/domain/zone/example.com/record/2222222222' }
)
```

Using the appropriate region code from the table above and the Application Key you previously created, run the following PowerShell and follow the instructions it gives. It will generate a URL you must open in a browser, verify the requested permissions, **set the Validity to "Unlimited"**, and click `Log In`.

```powershell
Invoke-OVHSetup -AppKey 'xxxxxxxxxxxx' -OVHRegion 'ovh-eu' -AccessRules $rules
```

#### Save the Resulting Consumer Key

After logging in successfully, you should be redirected to a success page on the Posh-ACME wiki. Press Enter in the PowerShell Window to be presented with your Consumer Key value which you should save for later.


## Using the Plugin

The App Key value will be used with the `OVHAppKey` parameter. The App Secret and Consumer Key values will either be used with `OVHAppSecret`/`OVHConsumerKey` or `OVHAppSecretInsecure`/`OVHConsumerKeyInsecure` depending on your Operating System and PowerShell version. The first pair are SecureString values that can be used on Windows or any OS running PowerShell 6.2 or later. The second pair are standard string values that can be used on any OS.

**IMPORTANT**: If the permissions on your consumer key only allow write access to specific records, you must add `OVHUseModify = $true` to your plugin arguments. This instructs the plugin to modify existing records instead of trying to create new ones from scratch which will fail.

### Windows or PS 6.2+

```powershell
$appSecret = Read-Host -Prompt "App Secret" -AsSecureString
$consumerKey = Read-Host -Prompt "Consumer Key" -AsSecureString
$pArgs = @{
    OVHAppKey = 'xxxxxxxxxxx'
    OVHAppSecret = $appSecret
    OVHConsumerKey = $consumerKey
    OVHRegion = 'ovh-eu'
}
New-PACertificate example.com -DnsPlugin OVH -PluginArgs $pArgs
```

### Non-Windows PS 6.1 and earlier

```powershell
$pArgs = @{
    OVHAppKey = 'xxxxxxxxxxxx'
    OVHAppSecretInsecure = 'yyyyyyyyyyyy'
    OVHConsumerKeyInsecure = 'zzzzzzzzzzzz'
    OVHRegion = 'ovh-eu'
}
New-PACertificate example.com -DnsPlugin OVH -PluginArgs $pArgs
```

### Specific Record Access

```powershell
$pArgs = @{
    OVHAppKey = 'xxxxxxxxxxxx'
    OVHAppSecretInsecure = 'yyyyyyyyyyyy'
    OVHConsumerKeyInsecure = 'zzzzzzzzzzzz'
    OVHRegion = 'ovh-eu'
    OVHUseModify = $true
}
New-PACertificate example.com -DnsPlugin OVH -PluginArgs $pArgs
```
