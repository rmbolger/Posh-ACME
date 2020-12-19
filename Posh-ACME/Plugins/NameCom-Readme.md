# How To Use the NameCom DNS Plugin

This plugin works against the [name.com](https://www.name.com/) domain registrar and DNS provider. It is assumed that you have already setup an account and purchased domain you will be working against. You must also be using name.com's own DNS hosting.

## Setup

First, go to the [Account API Settings](https://www.name.com/account/settings/api) page and create a new API token for your account. Make a note of both the token value and the username associated with the token. If the username is blank immediately following the token creation, try refreshing the page.

## Using the Plugin

With the username and token values from earlier, set the `NameComUsername` and `NameComToken` parameters and then pass them to `New-PACertificate` as follows:

```powershell
$pargs = @{NameComUserName='username'; NameComToken='XXXXXXXXXX'}
New-PACertificate example.com -Plugin NameCom -PluginArgs $pargs
```

If you are using name.com's API testing environment, you'll also need to include the `NameComUseTestEnv` switch in your plugin arguments like this:

```powershell
$pargs = @{NameComUserName='username'; NameComToken='XXXXXXXXXX'; NameComUseTestEnv=$true}
New-PACertificate example.com -Plugin NameCom -PluginArgs $pargs
```
