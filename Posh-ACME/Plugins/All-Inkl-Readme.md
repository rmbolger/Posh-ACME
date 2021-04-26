# How To Use the All-Inkl KAS DNS Plugin

This plugin works against the [All-Inkl](https://www.all-inkl.com/) KAS DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

Using the All-Inkl KAS API only requires your accounts username and password.

## Using the Plugin

In any case you have to provide the username with the `KasUsername` parameter.\
In addition you can provide the password as SecureString in plain text by using the `KasPwd` parameter or as sha1 hash by using the `KasPwdHash` parameter. In both cases this plugin only sends a sha1 hash of your password to the All-Inkl KAS API.

Alternatively you can handle the authentication yourself and provide a valid session id by specifying the `KasSession` parameter as SecureString.

```powershell
$pwd = Read-Host "All-Inkl KAS Password" -AsSecureString
$pArgs = @{
    KasUsername = 'myusername'
    KasPwd = $pwd
}
New-PACertificate example.com -Plugin All-Inkl -PluginArgs $pArgs
```