title: Ilait

# How To Use the Ilait DNS Plugin

This plugin works against the [Ilait](https://www.ilait.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

In order to use Ilait's API, you require only a regular user account with the appropriate permissions. (ideally "API Only")

## Using the Plugin

The Ilait API uses basic authentication, so provide the username and password of the desired account to use.

```powershell
$pArgs = @{
    IlaitCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin Ilait -PluginArgs $pArgs
```
