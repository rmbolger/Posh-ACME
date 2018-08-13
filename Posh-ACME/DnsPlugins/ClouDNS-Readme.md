# How To Use the ClouDNS DNS Plugin

This plugin works against the [ClouDNS](https://www.cloudns.net/aff/id/224075/) provider. It is assumed that you have already setup an account and registered the domains or zones you will be working against. It is also important to note that this provider does not allow API Access on its free account tier. But their paid plans are very reasonably priced. If you are a new customer, you can help me maintain this plugin by using the affiliate link above when you sign up.

## Setup

First, login to your account and go to the [API Settings](https://www.cloudns.net/api-settings/) page. Click the `Add new user` link and set a password and optional IP whitelist. After saving, make note of the `auth-id` value for this user.

### (Optional) Sub Users and Zone Delegation

The standard API users have complete access to your account. But for a bit more security, you can create sub-users that only have access to a subset of zones on your account. The web UI will let you create a sub-user, but I couldn't find a way to do the zone delegation without using the API. So here's how to do that.

First, make sure your sub-user has their "zone limit" set to however many zones you'll be delegating. Then use the following PowerShell to delegate each zone.

```powershell
$authID = '12345'        # this is the primary API user
$authPass = 'xxxxxxxxxx' # this is the password for the primary API user
$subID = '789'           # this is the ID of the sub-user
$zoneName = 'myzone.example.com' # the zone to delegate
Invoke-RestMethod "https://api.cloudns.net/sub-users/delegate-zone.json?auth-id=$authID&auth-password=$authPass&id=$subID&zone=$zoneName"
```

## Using the Plugin

There are two parameter sets you can use with this plugin. One is intended for Windows OSes while the other is intended for non-Windows until PowerShell Core fixes [this issue](https://github.com/PowerShell/PowerShell/issues/1654). The non-Windows API Key parameter is called `CDPasswordInsecure` because the issue prevents PowerShell from encrypting/decrypting SecureString and PSCredential objects.

### Windows

```powershell
$cdPass = Read-Host "Password" -AsSecureString
$cdParams = @{CDUserType='auth-id';CDUsername='12345';CDPassword=$cdPass}
New-PACertificate test.example.com -DnsPlugin ClouDNS -PluginArgs $cdParams
```

### Non-Windows

```powershell
$cdParams = @{CDUserType='auth-id';CDUsername='12345';CDPasswordInsecure='xxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin ClouDNS -PluginArgs $cdParams
```
