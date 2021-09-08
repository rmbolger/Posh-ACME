title: LuaDns

# How To Use the LuaDns DNS Plugin

This plugin works against the [LuaDns](https://www.luadns.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

First, go to the [Account Settings](https://api.luadns.com/settings) page and make sure the `Enable API Access` box is checked. Then click `Show Token` to see the API token for your account. You'll also need the email address associated with the account.

## Using the Plugin

The account email address and API token should be used to create a PSCredential object that you'll pass to the `LuaCredential` parameter.

!!! warning
    The `LuaUsername` and `LuaPassword` parameters are deprecated and will be removed in the next major module version. If you are using them, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    LuaCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin LuaDns -PluginArgs $pArgs
```
