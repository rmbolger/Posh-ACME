# How To Use the Azure DNS Plugin

This plugin works against the [Azure DNS](https://azure.microsoft.com/en-us/services/dns/) provider. It is assumed that you already have an active subscription with at least one DNS zone and an account with access to create roles and app registrations. The commands used in this guide will also make use of the [AzureRM.Profile](https://www.powershellgallery.com/packages/AzureRM.profile/5.0.1) and [AzureRM.Dns](https://www.powershellgallery.com/packages/AzureRM.Dns/5.0.0) modules. But they are not required to use the plugin normally.

## Setup

We need to create an "App registration" which is basically a service account in Azure AD and give it permission to modify TXT records for the zones we'll be issuing certificates in.

### Connect to Azure

Using the account with access to create roles and app registrations, connect to Azure with the following commands.

```powershell
$azcred = Get-Credential
$profile = Connect-AzureRMAccount -Cred $azcred
$profile
```

The `$profile` variable output will contain some fields we'll need later such as `SubscriptionId` and `TenantId`.

### Create a Service Account

TODO

### Create a Custom Role

TODO

### Create a Resource Group and Add Zones

TODO

### Assign Custom Role to Resource Group

TODO

## Using the Plugin

TODO
