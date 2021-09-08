title: Loopia

# How to use the Loopia Plugin

This plugin works against the [Loopia](https://www.loopia.com/loopiadns/) DNS provider. It presumes
that you have already set up an account and registered or transferred the domain(s) you are targeting. You will also need to be subscribed to their Advanced DNS product.

## Setup

From the [customer zone](https://customerzone.loopia.com), click `API user` and then `Create API User`. Configure an appropriate Username and Password and select `Advanced privileges`. When complete, open the details for the user you created and select the following privileges:

- addSubdomain
- addZoneRecord
- getDomains
- getSubdomains
- getZoneRecords
- removeSubdomain
- removeZoneRecord

Keep in mind, the username you selected will end with `@loopiaapi` and you will need to include the full `username@loopiaapi` value in the plugin parameters later.

## Using the Plugin

The username is used with the `LoopiaUser` parameter and the password is used with the `LoopiaPass` SecureString parameter.

!!! warning
    The `LoopiaPassInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs @{
    LoopiaUser = 'username@loopiaapi'
    LoopiaPass = (Read-Host 'Password' -AsSecureString)
}
New-PACertificate example.com -Plugin Loopia -PluginArgs $pArgs
```
