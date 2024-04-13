title: WebsupportSK

# How To Use the WebsupportSK DNS Plugin

This plugin works against the [Websupport.sk](https://www.websupport.sk/?ref=NTIqFFo7Rg) provider. Former users of Active24 may have been migrated to this provider for DNS API purposes. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

Login to the web portal and go to the `Security and login` portion of your Personal settings. Near the bottom, there should be an `API Authentication` section.

* Click `Generate new API access`
* Type: Standard

Record the Identifier and Secret values for the generated key.

## Using the Plugin

The API Identifier and Secret values will be used as the username and password in a PSCredential object called `WskCredential`.

!!! warning
    Websupport.sk advertises that DNS changes take 5 minutes apply to all nameservers. When using the plugin, you should override the default sleep value with `-DnsSleep 300` or more.

```powershell
$pArgs = @{
    WskCredential = Get-Credential
}
New-PACertificate example.com -Plugin WebsupportSk -PluginArgs $pArgs -DnsSleep 300
```
