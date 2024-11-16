title: INWX

# How To Use the INWX DNS Plugin

This plugin works against the [INWX](https://www.inwx.de/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

There is no special setup needed, as INWX uses a username and password for API authentication. However, it makes sense to set up a [dedicated API user](https://www.inwx.de/en/account) in your account with the "DNS Management" role for automation purposes. This way, nothing besides your DNS settings is at risk if your API credentials are compromised—your domain ownership and other user accounts will remain secure.

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


The API key consist of two values. The X-APP-ID and X-API-KEY. Here are two examples on how you can use them:

```powershell
## The name should be value of X-APP-ID
## The password should be value of X-API-KEY
$pArgs = @{EuroDNS_Creds = Get-Credential}
New-PACertificate example.com -Plugin EuroDNS -PluginArgs $pArgs
```

For a more automated approach (This method assumes you understand the risks and methods to secure the below credentials):

```powershell
$username = "My_X-APP-ID_Value"
$password = "My_X-API-Key_Value" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $password)
$pArgs = @{EuroDNS_Creds = $cred}
New-PACertificate example.com -Plugin EuroDNS -PluginArgs $pArgs
```