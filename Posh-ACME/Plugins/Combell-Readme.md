# How To Use the Combell DNS Plugin

This plugin works against the [Combell][1] DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

[Combell NV][1] is a hosting provider based in Belgium. Besides offering hosting solutions, Combell NV is also an [ICANN Accredited Registrar under IANA number 1467](https://www.icann.org/en/accredited-registrars?sort-direction=asc&sort-param=name&page=1&iana-number=1467&country=Belgium).

## Setup

https://api.combell.com/v2/documentation#section/Authentication



Using Simply.com API requires only your account name or account number and API Key which can be found on the [account](https://www.simply.com/en/controlpanel/account/) page.

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

[1] https://www.combell.com/
