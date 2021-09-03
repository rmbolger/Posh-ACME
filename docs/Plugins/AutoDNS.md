title: AutoDNS

# How To Use the AutoDNS DNS Plugin

This plugin works against any DNS provider that utilizes the [AutoDNS](https://help.internetx.com/x/Qwfj) XML API from [InternetX](https://www.internetx.com/). [Schlundtech](https://www.schlundtech.de/) is an example of a registrar who uses this API. It is assumed that you have already setup an account and registered the domains or zones you will be working against.

## Setup

In addition to your username and password, you will also need a "Context" value for your account. This is typically a number and varies per provider. The plugin defaults to `4`. If you are not using InternetX directly, you will also need the XML gateway URL. The plugin defaults to `gateway.autodns.com`.

## Using the Plugin

`AutoDNSUser`, `AutoDNSContext`, and `AutoDNSGateway` are specified using regular string values. `AutoDNSPassword` is a SecureString value.

*NOTE: The `AutoDNSPasswordInsecure` parameter is deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pass = Read-Host -Prompt "Password" -AsSecureString
$pArgs = @{
    AutoDNSUser = 'myusername'
    AutoDNSPassword = $pass
    AutoDNSContext = '4'
    AutoDNSGateway = 'gateway.autodns.com'
}
New-PACertificate example.com -Plugin AutoDNS -PluginArgs $pArgs
```
