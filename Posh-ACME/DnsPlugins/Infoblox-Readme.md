# How To Use the Infoblox DNS Plugin

This plugin works against [Infoblox DDI](https://www.infoblox.com/products/ddi/). It is assumed that you have a set of credentials and permissions to modify TXT records for the zone(s) you will be working against.

**This plugin currently does not work on non-Windows OSes in PowerShell Core. [Click here](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) for details.**

## Setup

The Infoblox WAPI (REST API) takes a standard username/password combo for authentication. There is no setup aside from knowing those credentials and making sure you have enough permissions. If your organization is using split-brain DNS using DNS Views, you should also know which DNS View to write against that is internet-facing.

## Using the Plugin

```powershell
# create the credential object
$ibcred = Get-Credential

# build the parameters
$ibParams = @{IBServer='gridmaster.example.com';IBView='External';IBCred=$ibcred}

# generate the cert
New-PACertificate test.example.com -DnsPlugin Infoblox -PluginArgs $ibParams
```

If your grid is still using a self-signed SSL/TLS certificate, you may also need to include the `IBIgnoreCert` parameter.

```powershell
$ibParams = @{IBServer='gridmaster.example.com';IBView='External';IBCred=$ibcred;IBIgnoreCert=$true}
```
