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

There are two parameter sets you can use with this plugin. The first takes `LoopiaUser` as the API username you previously created and the password is used with `LoopiaPass` as a SecureString object. But it can only be used from Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The second parameter set also takes `LoopiaUser` but uses `LoopiaPassInsecure` for the password as a standard String object.

### Windows or PS 6.2+

```powershell
$pass = Read-Host "Loopia API Password" -AsSecureString
$loopiaParams = @{LoopiaUser='username@loopiaapi';LoopiaPass=$pass}
New-PACertificate example.com -Plugin Loopia -PluginArgs $loopiaParams
```

### Any OS

```powershell
$loopiaParams = @{LoopiaUser='username@loopiaapi';LoopiaPass='xxxxxxxx'}
New-PACertificate example.com -Plugin Loopia -PluginArgs $loopiaParams
```
