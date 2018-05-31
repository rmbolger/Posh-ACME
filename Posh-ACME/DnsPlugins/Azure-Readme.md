# How To Use the Azure DNS Plugin

This plugin works against the [Azure DNS](https://azure.microsoft.com/en-us/services/dns/) provider. It is assumed that you already have an active subscription with at least one DNS zone, associated Resource Group, and an account with access to create roles and app registrations. The commands used in this guide will also make use of the [AzureRM.Profile](https://www.powershellgallery.com/packages/AzureRM.profile/5.0.1), [AzureRM.Resources](https://www.powershellgallery.com/packages/AzureRM.Resources/6.0.0), and [AzureRM.Dns](https://www.powershellgallery.com/packages/AzureRM.Dns/5.0.0) modules. But they are not required to use the plugin normally.

**This plugin currently does not work on non-Windows OSes in PowerShell Core. [Click here](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) for details.**

## Setup

There are two ways to set up required authorization for modifying the DNS records.
You can either create an "App registration" which is basically a service account in Azure AD and give it permission to modify TXT records for the zones we'll be issuing certificates in
or you can send in an authorization token that you can generate in several ways (see **Provided Authorization Token** below)

### Connect to Azure

Using the account with access to create roles and app registrations, connect to Azure with the following commands.

```powershell
$azcred = Get-Credential
$profile = Connect-AzureRMAccount -Cred $azcred
$profile
```

The `$profile` variable output will contain some fields we'll need later such as `SubscriptionId` and `TenantId`.

### Provided Authorization Token

You can use an existing user or application principal, e.g. a [Managed Service Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview) and assign it the role of managing DNS TXT records.

To use the account you are currently logged in to with Azure CLI 2.0, use the following command to generate a token. Remember to use the correct subscription.
```powershell
az account list # shows all subscriptions - the one marked as "isDefault": true will be used to create the token
$token = (az account get-access-token --resource 'https://management.core.windows.net/' | ConvertFrom-Json).accessToken
```

To get a token for the MSI when running in a VM, Azure Function or App Service - please refer to the following documentation. Remember to pass in the correct resource uri: **https://management.core.windows.net/**

* [Getting a token for an MSI-enabled VM](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/how-to-use-vm-token)
* [Getting a token for an MSI-enabled App Service or Function](https://docs.microsoft.com/en-us/azure/app-service/app-service-managed-service-identity)

If you use MSI then you must also assign the role to the Service Principal assigned so you need to ObjectID (Active Directory ID) of that Principal and follow the role assignment step below.
Refer to the MSI documentation above on how to find it through the Azure portal or scripting tools.

### Create a Service Account

The other option is to create a new service account to use with Posh-ACME. Ideally, the password should be long and randomized. The account will show up in the "App registrations" section of your Azure Active Directory.
As an alternative you can use

```powershell
$svcPass = Read-Host Pass -AsSecureString
$svcAcct = New-AzureRmADServicePrincipal -DisplayName PoshACME -Password $svcPass
$svcAcct
```

The `ApplicationId` field in the variable output will be used later when assigning permissions and creating the credential object needed for the plugin-

### Create a Custom Role

To lock down the service account as much as possible, we'll create a custom role based on the default `DNS Zone Contributor` role.

```powershell
$roleDef = Get-AzureRmRoleDefinition -Name "DNS Zone Contributor"
$roleDef.Id = $null
$roleDef.Name = "DNS TXT Contributor"
$roleDef.Description = "Manage DNS TXT records only."
$roleDef.Actions.RemoveRange(0,$roleDef.Actions.Count)
$roleDef.Actions.Add("Microsoft.Network/dnsZones/TXT/*")
$roleDef.Actions.Add("Microsoft.Network/dnsZones/read")
$roleDef.Actions.Add("Microsoft.Authorization/*/read")
$roleDef.Actions.Add("Microsoft.Insights/alertRules/*")
$roleDef.Actions.Add("Microsoft.ResourceHealth/availabilityStatuses/read")
$roleDef.Actions.Add("Microsoft.Resources/deployments/read")
$roleDef.Actions.Add("Microsoft.Resources/subscriptions/resourceGroups/read")
$roleDef.AssignableScopes.Clear()
$roleDef.AssignableScopes.Add("/subscriptions/$($profile.Context.Subscription.Id)")

$role = New-AzureRmRoleDefinition $roleDef
$role
```

### Assign Permissions To Resource Group

When you created the DNS zones, you had to assign them to a resource group. If they're all in the same Resource Group, this step will be much quicker. If not, you should either move them all to the same Resource Group or you'll have to repeat this step for each one.

```powershell
# get a reference to the Resource Group
$resGroup = Get-AzureRmResourceGroup "MyResourceGroup"

# associate the service account and custom role to this resource group
$appID = $svcAcct.ApplicationId.ToString()
$resName = $resGroup.ResourceGroupName
New-AzureRmRoleAssignment -ApplicationId $appID -ResourceGroupName $resName -RoleDefinitionName $role.Name
```

## Using the Plugin

There are two or three required parameters for the plugin, `AZSubscriptionId` and either `AZProvidedToken` or both `AZTenantId` and `AZAppCred`.
The subscription and tentant IDs you should have from earlier, but you can also look them up in the portal on the Properties page of a DNS zone and Azure AD instance respectively. The app credential is just a standard `PSCredential` object with the service account's `ApplicationId` guid as the username. The password is whatever you originally set for it.

```powershell
# build the parameter hashtable for tenant id and credentials
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZTenantId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZAppCred=(Get-Credential)
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```

```powershell
# build the parameter hashtable for a provided token
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZProvidedToken='<token>'
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```
