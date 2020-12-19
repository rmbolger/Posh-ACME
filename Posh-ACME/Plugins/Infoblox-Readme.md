# How To Use the Infoblox DNS Plugin

This plugin works against [Infoblox DDI](https://www.infoblox.com/products/ddi/). It is assumed that you have a set of credentials and permissions to modify TXT records for the zone(s) you will be working against.

## Setup

The Infoblox WAPI (REST API) takes a standard username/password combo for authentication. There is no setup aside from knowing those credentials and making sure you have enough permissions. If your organization is using split-brain DNS using DNS Views, you should also know which DNS View to write against that is internet-facing. **Note: The DNS View name is case-sensitive.**

## Using the Plugin

There are two slightly different ways to use the plugin depending on your OS platform. If you're on Windows, you'll be creating a `PSCredential` object for the username and password. On non-Windows, you'll pass the username and password in separately as standard string objects.

You need to set the server which is usually the grid master. By default, the DNS View is set to `default`. You can use the `IBView` parameter to specify a different one. If your grid still uses the default self-signed certificate, you'll also want to set `IBIgnoreCert=$true`.

Here are a couple examples.

### Windows

```powershell
# create the credential object
$ibcred = Get-Credential

# build the parameter hashtable
$ibParams = @{ IBServer='gridmaster.example.com'; IBView='External'; IBCred=$ibcred; IBIgnoreCert=$true }

# generate the cert
New-PACertificate example.com -Plugin Infoblox -PluginArgs $ibParams
```

## Non-Windows

```powershell
# build the parameter hashtable
$ibParams = @{
    IBServer='gridmaster.example.com';
    IBUsername='myusername';
    IBPassword='xxxxxxxxxxxxxx';
    IBView='External';
    IBIgnoreCert=$true
}

# generate the cert
New-PACertificate example.com -Plugin Infoblox -PluginArgs $ibParams
```
