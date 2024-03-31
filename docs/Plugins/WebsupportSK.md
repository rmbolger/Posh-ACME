title: WebsupportSK

# How To Use the WebsupportSK DNS Plugin

This plugin works against the [Websupport.sk](https://www.websupport.sk/?ref=NTIqFFo7Rg) provider. Former users of Active24 may have been migrated to this provider for DNS API purposes. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

Login to the web portal and go to the `Security and login` portion of your Personal settings. Near the bottom, there should be an `API Authentication` section.

* Click `Generate new API access`
* Type: Standard

Record the Identifier and Secret values for the generated key.

From the `Services` section of the web portal, you will need to gather the ID value for each domain in your certificate. Click each domain and record the number at the end of the URL. For example if the URL is `https://admin.websupport.sk/en/dashboard/service/12345`, you would record `12345`. These are your Service ID values.

!!! warning
    Due to limitations in the Websupport.sk API, this plugin will only work if there is at least one DNS record already in the root of your domain. It can be any type of record as long as it is for the root of the domain.

## Using the Plugin

The API Identifier and Secret values will be used as the username and password in a PSCredential object called `WskCredential`. The Service ID values will be used in an array called `WskServiceId`.

!!! warning
    Websupport.sk advertises that DNS changes take 5 minutes apply to all nameservers. When using the plugin, you should override the default sleep value with `-DnsSleep 300` or more.

```powershell
$pArgs = @{
    WskCredential = Get-Credential
    WskServiceId = '12345','23456'
}
New-PACertificate example.com -Plugin WebsupportSk -PluginArgs $pArgs -DnsSleep 300
```
