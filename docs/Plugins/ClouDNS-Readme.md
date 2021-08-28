# How To Use the ClouDNS DNS Plugin

This plugin works against the [ClouDNS](https://www.cloudns.net/aff/id/224075/) provider. It is assumed that you have already setup an account and registered the domains or zones you will be working against.

**Note:** This provider does not allow API Access on its free account tier. If you sign up for a premium plan trial and let it expire, the plugin will stop working unless you upgrade your account to premium again. Their premium plans are very reasonably priced and if you are a new customer, you can help me maintain this plugin by using this [affiliate link](https://www.cloudns.net/aff/id/224075/) when you sign up.

## Setup

First, login to your account and go to the [API Settings](https://www.cloudns.net/api-settings/) page. Click the `Add new user` link and set a password and optional IP whitelist. After saving, make note of the `auth-id` value for this user.

### (Optional) Sub Users and Zone Delegation

The standard API users have complete access to your account. But for a bit more security, you can create sub-users that only have access to a subset of zones on your account. Click the `Add new sub-user` link from the [API Settings](https://www.cloudns.net/api-settings/) page. Set a password and set the `DNS Zones` value to the number of zones you'll be delegating the user to. The rest of the fields are either optional or can be set to 0.

After the user is created, click the text link in the DNS Zones column for the user that should be something like "0 / X" where X is the number of zone you configured for delegation. This will pop up a dialog box and let you add the specific zones you are delegating.

Make a note of the `sub-auth-id` or `sub-auth-user` name you set for later.

## Using the Plugin

The `CDUserType` parameter must be set to either `auth-id`, `sub-auth-id`, or `sub-auth-user` depending on the type of credential you are using. The `CDUsername` parameter should be set to the ID or username of the user. The password can be set using either `CDPassword` as a [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring) or `CDPasswordInsecure` as a regular string. The SecureString version can only be used on Windows OSes or any OS with PowerShell 6.2 or later. Non-Windows OSes on PowerShell 6.0-6.1 must use the regular string version due to [this issue](https://github.com/PowerShell/PowerShell/issues/1654).

By default the plugin assumes Posh-ACME's default DNS propagation delay mechanics will be used. But ClouDNS also supports a polling API to check whether record changes have propagated to the nameservers. To use this instead of the default mechanics, add a `CDPollPropagation = $true` parameter to your plugin args. By default, it will timeout after 5 minutes if the polling API never returns a success. You can override the timeout value with `CDPollTimeout` in seconds. When using CDPollPropagation, you should also set Posh-ACME's `DNSSleep` parameter to 0 unless you are using additional plugins that don't support their own form of propagation polling.

### Windows and/or PS 6.2+ only

```powershell
$secPass = Read-Host "Password" -AsSecureString

# standard Posh-ACME propagation delay
$pArgs = @{
    CDUserType = 'auth-id';
    CDUsername = '12345';
    CDPassword = $secPass
}
New-PACertificate example.com -Plugin ClouDNS -PluginArgs $pArgs

# ClouDNS propagation polling
$pArgs = @{
    CDUserType = 'auth-id';
    CDUsername = '12345';
    CDPassword = $secPass;
    CDPollPropagation = $true
}
New-PACertificate example.com -Plugin ClouDNS -PluginArgs $pArgs -DnsSleep 0
```

### Any OS

```powershell
# standard Posh-ACME propagation delay
$pArgs = @{
    CDUserType = 'auth-id';
    CDUsername = '12345';
    CDPasswordInsecure = 'xxxxxxxx'
}
New-PACertificate example.com -Plugin ClouDNS -PluginArgs $pArgs

# ClouDNS propagation polling
$pArgs = @{
    CDUserType = 'auth-id';
    CDUsername = '12345';
    CDPasswordInsecure = 'xxxxxxxx';
    CDPollPropagation = $true
}
New-PACertificate example.com -Plugin ClouDNS -PluginArgs $pArgs -DnsSleep 0
```
