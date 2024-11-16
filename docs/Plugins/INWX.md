title: INWX

# How To Use the INWX DNS Plugin

This plugin works against the [INWX](https://www.inwx.de/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

There is no special setup needed, as INWX uses a username and password for API authentication. However, it makes sense to set up a [dedicated API user](https://www.inwx.de/en/account) in your account with the "DNS Management" role for automation purposes. This way, nothing besides your DNS settings is at risk if your API credentials are compromised—your domain ownership and other user accounts will remain secure.

!!! note
    This plugin does not work with [mobile TAN](https://kb.inwx.com/en-us/5-customer-details/70-what-is-the-mobile-tan-service-and-how-can-i-activate-it)-enabled accounts yet.

## Using the Plugin

You will need to provide the username as String to `INWXUsername` and the password belonging to the username as a SecureString value to `INWXPassword`.

```powershell
$pArgs = @{
    INWXUsername = (Read-Host 'INWX API username')
    INWXPassword = (Read-Host 'INWX API password' -AsSecureString)
}
New-PACertificate example.com -Plugin INWX -PluginArgs $pArgs
```
