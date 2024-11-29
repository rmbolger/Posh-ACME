title: INWX

# How To Use the INWX DNS Plugin

This plugin works against the [INWX](https://www.inwx.de/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

There is no special setup required, as INWX uses a username and password for API authentication. However, it is recommended to [set up](https://www.inwx.de/en/account) a dedicated API sub-user for automation purposes, with only the "DNS Management" role assigned. This way, if your API credentials are compromised, only your DNS settings are at risk—your domain ownership and other user accounts will remain secure.

## Using the Plugin

You will need to provide the username as String to `INWXUsername` and the password associated with the username as a SecureString value to `INWXPassword`.

```powershell
$pArgs = @{
    INWXUsername = (Read-Host "INWX API username")
    INWXPassword = (Read-Host "INWX API password" -AsSecureString)
}
New-PACertificate "example.com" -Plugin "INWX" -PluginArgs $pArgs
```

For a more automated approach (assuming you understand the risks and methods to secure the below credentials):

```powershell
$pArgs = @{
    INWXUsername = "username"
    INWXPassword = ConvertTo-SecureString -String "password belonging to username" -AsPlainText -Force
}
New-PACertificate "example.com" -Plugin "INWX" -PluginArgs $pArgs
```

This plugin also supports [mobile TAN](https://kb.inwx.com/en-us/5-customer-details/70-what-is-the-mobile-tan-service-and-how-can-i-activate-it)-enabled accounts. If your account is secured by mobile TAN ("2FA", "two-factor authentication"), you must define the shared secret (usually presented below the QR code during mobile TAN setup) as a SecureString to `INWXSharedSecret`. This allows the plugin to generate OTP codes. The shared secret is NOT not the 6-digit code you need to enter when logging in. If you are not using 2FA, leave this parameter undefined or set it to `$null`:

```powershell
$pArgs = @{
    INWXUsername = "username"
    INWXPassword = ConvertTo-SecureString -String "password belonging to username" -AsPlainText -Force
    INWXSharedSecret = ConvertTo-SecureString -String "2FA_SHARED_SECRET_32CHARS" -AsPlainText -Force
}
New-PACertificate "example.com" -Plugin "INWX" -PluginArgs $pArgs
```
