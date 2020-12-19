# How To Use the Simply DNS Plugin

This plugin works against the [Simply](https://www.simply.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

Using Simply API requires only your account name or account number and API Key which can be found on the [account](https://www.simply.com/en/controlpanel/account/) page.

## Using the Plugin

Your account name/number is used with the `SimplyAccount` parameter. The API key can be used with `SimplyAPIKey` as a SecureString or `SimplyAPIKeyInsecure` as a standard string. The SecureString version should only be used on Windows or any OS with PowerShell 6.2 or later.


### Windows or PS 6.2+

```powershell
$pArgs = @{
    SimplyAccount = 'S123456'
    SimplyAPIKey = (Read-Host 'Enter Key' -AsSecureString)
}
New-PACertificate example.com -Plugin Simply -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{
    SimplyAccount = 'S123456'
    SimplyAPIKeyInsecure = 'xxxxxxxxxxxx'
}
New-PACertificate example.com -Plugin Simply -PluginArgs $pArgs
```
