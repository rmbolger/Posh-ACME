# How To Use the HurricaneElectric Plugin

This plugin works against [Hurricane Electric DNS](https://dns.he.net/). It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

*NOTE: Hurricane Electric can be configured as a secondary to your primary zones hosted elsewhere. This plugin will not work for secondary zones. You must use a plugin that is able to modify the primary nameservers.*

## Setup

There's not really any setup aside from knowing your account credentials. Hurricane Electric doesn't currently support an API for manipulating DNS records. So this plugin utilizes web scraping to accomplish the task. That also means it is more likely to break if the site owner ever changes their HTML markup. So be wary of depending on this for critical projects.

## Using the Plugin

Your account credentials will either be used with the `HECredential` parameter or `HEUsername`/`HEPassword` parameters. HECredential uses a PSCredential object that should only be used on Windows or any OS that has PowerShell 6.2 or later. Any environment can use the HEUsername/HEPassword option.

### Windows or PS 6.2+

```powershell
# create the plugin args hashtable
$pArgs = @{ HECredential = (Get-Credential) }

# generate the cert
New-PACertificate example.com -Plugin HurricaneElectric -PluginArgs $pArgs
```

## Any OS

```powershell
# create the plugin args hashtable
$pArgs = @{
    HEUsername = 'myusername'
    HEPassword = 'mypassword'
}

# generate the cert
New-PACertificate example.com -Plugin HurricaneElectric -PluginArgs $pArgs
```
