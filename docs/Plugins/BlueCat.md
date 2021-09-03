title: BlueCat

# How To Use the BlueCat DNS Plugin

This plugin works against the [BlueCat Address Manager](https://www.bluecatnetworks.com/platform/management/bluecat-address-manager/) DNS provider. It is assumed that you have already have an account that is an "API User" and have created the DNS zone(s) you will be working against. This plugin has been tested against version 8.1.1.

## Using the Plugin

Due to the potentially short lifetime of a BAM auth token you must pass the username and password as a PSCredential object using the `BlueCatCredential` parameter. You also need to provide the API uri as `BlueCatUri`. In addition you must also pass the Configuration name as `BlueCatConfig`, the DNS View name as `BlueCatView`, and the list of DNS servers to deploy as `BlueCatDeployTargets`.

*NOTE: The `BlueCatUsername` and `BlueCatPassword` parameters are deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$BlueCatParams = @{
    BlueCatUsername='xxxxxxxx'
    BlueCatPassword='xxxxxxxx'
    BlueCatUri='https://FQDN//Services/API'
    BlueCatConfig='foobar'
    BlueCatView='foobaz'
    BlueCatDeployTargets=@('FQDN1', 'FQDN2', 'FQDN3')
}
New-PACertificate example.com -Plugin BlueCat -PluginArgs $BlueCatParams
```
