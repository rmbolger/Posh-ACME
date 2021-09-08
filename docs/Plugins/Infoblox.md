title: Infoblox

# How To Use the Infoblox DNS Plugin

This plugin works against [Infoblox DDI](https://www.infoblox.com/products/ddi/). It is assumed that you have a set of credentials and permissions to modify TXT records for the zone(s) you will be working against.

## Setup

The Infoblox WAPI (REST API) takes a standard username/password combo for authentication. There is no setup aside from knowing those credentials and making sure you have enough permissions. If your organization is using split-brain DNS using DNS Views, you should also know which DNS View to write against that is internet-facing. **The DNS View name is case-sensitive.**

## Using the Plugin

Your username and password are used with the `IBCred` parameter as a PSCredential object. You need to set the `IBServer` parameter which is usually the grid master. By default, the DNS View is set to `default`. You can use the `IBView` parameter to specify a different one. If your grid still uses the default self-signed certificate, you'll also want to set `IBIgnoreCert=$true`.

!!! warning
    The `IBUsername` and `IBPassword` parameters are deprecated and will be removed in the next major module version. If you are using them, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    IBServer = 'gridmaster.example.com'
    IBView = 'External'
    IBCred = (Get-Credential)
    IBIgnoreCert = $true
}
New-PACertificate example.com -Plugin Infoblox -PluginArgs $pArgs
```
