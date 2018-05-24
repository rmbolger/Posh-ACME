# How To Use the Azure DNS Plugin

This plugin works against the [Azure DNS](https://azure.microsoft.com/en-us/services/dns/) provider. It is assumed that you already have an active subscription with at least one DNS zone, associated Resource Group, and an account with access to create roles and app registrations. The commands used in this guide will also make use of the [AzureRM.Profile](https://www.powershellgallery.com/packages/AzureRM.profile/5.0.1), [AzureRM.Resources](https://www.powershellgallery.com/packages/AzureRM.Resources/6.0.0), and [AzureRM.Dns](https://www.powershellgallery.com/packages/AzureRM.Dns/5.0.0) modules. But they are not required to use the plugin normally.

**This plugin currently does not work on non-Windows OSes in PowerShell Core. [Click here](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) for details.**

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

Create a new service account to use with Posh-ACME. Ideally, the password should be long and randomized. The account will show up in the "App registrations" section of your Azure Active Directory.

```powershell
$svcPass = Read-Host Pass -AsSecureString
$svcAcct = New-AzureRmADServicePrincipal -DisplayName PoshACME -Password $svcPass
$svcAcct
```

The `ApplicationId` field in the variable output will be used later when assigning permissions and creating the credential object needed for the plugin.

### Create a Custom Role

To lock down the service account as much as possible, we'll create a custom role based on the default `DNS Zone Contributor` role.

```powershell
$roleDef = Get-AzureRmRoleDefinition -Name "DNS Zone Contributor"
$roleDef.Id = $null
$roleDef.Name = "DNS TXT Contributor"
$roleDef.Description = "Manage DNS TXT records only."
$roleDef.Actions.RemoveRange(0,$role.Actions.Count)
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

There are three required parameters for the plugin, `AZSubscriptionId`, `AZTenantId`, and `AZAppCred`. The subscription and tentant IDs you should have from earlier. But you can also look them up in the portal on the Properties page of a DNS zone and Azure AD instance respectively. The app credential is just a standard `PSCredential` object with the service account's `ApplicationId` guid as the username. The password is whatever you originally set for it.

```powershell
# build the parameter hashtable
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZTenantId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZAppCred=(Get-Credential)
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```
