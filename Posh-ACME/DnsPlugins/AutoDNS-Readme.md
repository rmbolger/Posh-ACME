# How To Use the AutoDNS DNS Plugin

This plugin works against any DNS provider that utilizes the [AutoDNS](https://help.internetx.com/x/Qwfj) XML API from [InternetX](https://www.internetx.com/). [Schlundtech](https://www.schlundtech.de/) is an example of a registrar who uses this API. It is assumed that you have already setup an account and registered the domains or zones you will be working against.

## Setup

In addition to your username and password, you will also need a "Context" value for your account. This is typically a number and varies per provider. The plugin defaults to `4`. If you are not using InternetX directly, you will also need the XML gateway URL. The plugin defaults to `gateway.autodns.com`.

## Using the Plugin

There are two parameter sets you can use with this plugin. One is intended for Windows OSes while the other is intended for non-Windows until PowerShell Core fixes [this issue](https://github.com/PowerShell/PowerShell/issues/1654). The non-Windows password parameter is called `AutoDNSPasswordInsecure` because the issue prevents PowerShell from encrypting/decrypting SecureString and PSCredential objects.

### Windows

```powershell
$pass = Read-Host -Prompt "Password" -AsSecureString
$params = @{
    AutoDNSUser='myusername'
    AutoDNSPassword=$pass
    AutoDNSContext='4'
    AutoDNSGateway='gateway.autodns.com'
}
New-PACertificate test.example.com -DnsPlugin AutoDNS -PluginArgs $params
```

### Non-Windows

```powershell
$params = @{
    AutoDNSUser='myusername'
    AutoDNSPasswordInsecure='mypassword'
    AutoDNSContext='4'
    AutoDNSGateway='gateway.autodns.com'
}
New-PACertificate test.example.com -DnsPlugin AutoDNS -PluginArgs $params
```
