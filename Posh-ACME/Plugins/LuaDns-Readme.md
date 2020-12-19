# How To Use the LuaDns DNS Plugin

This plugin works against the [LuaDns](https://www.luadns.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the [Account Settings](https://api.luadns.com/settings) page and make sure the `Enable API Access` box is checked. Then click `Show Token` to see the API token for your account. You'll also need the email address associated with the account.

## Using the Plugin

### Windows

We need to put the account email address and API token in a PSCredential object and use it with the `LuaCredential` parameter.

```powershell
$cred = Get-Credential
New-PACertificate example.com -Plugin LuaDns -PluginArgs @{LuaCredential=$cred}
```

### Non-Windows

We need to set `LuaUsername` as the account email address and `LuaPassword` as the API token.

```powershell
$pargs = @{ LuaUsername = 'user@example.com'; LuaPassword = 'xxxxxxxxxxxx' }
New-PACertificate example.com -Plugin LuaDns -PluginArgs $pargs
```
