# How To Use the DynECT DNS Plugin

This plugin works against DynECT DNS provider.
It requires PoshDynDnsApi powershell module to be installed in order to work correctly. - However, if this module is missing, it will be installed on first run (You will be prompted if you want to install or not.)

## Setup

In addition to your username and password, you will also need a "customer" name, in order to make a successful connection.
Customer name can be found on the home dashboard when logged into the dyn ECT portal.

### Any OS

```powershell
$pass = Read-Host -Prompt "Password" -AsSecureString
$params = @{
    user='myusername'
    pass=$pass
    customer='examplecustomer'
    zone='example.com'
}
New-PACertificate *.test.example.com -DnsPlugin DynECT -PluginArgs $params
```
