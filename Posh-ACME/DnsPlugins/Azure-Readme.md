# How To Use the Azure DNS Plugin

This plugin works against the [Azure DNS](https://azure.microsoft.com/en-us/services/dns/) provider. It is assumed that you already have an active subscription with at least one DNS zone, associated Resource Group, and an account with access to create roles and app registrations. The commands used in this guide will also make use of the [AzureRM.Profile](https://www.powershellgallery.com/packages/AzureRM.profile), [AzureRM.Resources](https://www.powershellgallery.com/packages/AzureRM.Resources), [AzureRM.Compute](https://www.powershellgallery.com/packages/AzureRM.Compute), and [AzureRM.Dns](https://www.powershellgallery.com/packages/AzureRM.Dns) modules for setting up permissions in Azure. But they are not required to use the plugin normally.

## Setup

This plugin has three distinct methods for authentication against Azure. The first involves specifying a Tenant ID and credentials for an account or app registration. The second requires an existing [OAuth 2.0 access token](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-protocols-oauth-code) which would generally be used for short lived services or environments where Azure authentication is being handled externally to the Posh-ACME module. The last is for systems running within Azure that have a [Managed Service Identity (MSI)](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview) and utilizes the [Instance Metadata Service (IMDS)](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) to request an access token.

**The explicit credential method does not currently work on non-Windows OSes in PowerShell Core. [Click here](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) for details.**

All methods require that the identity being used to authenticate has been given access to modify TXT records in the specified Azure subscription. If you have already done that, you can skip most of the following setup.

### Connect to Azure

Using an account with access to create roles and app registrations, connect to Azure with the following commands.

```powershell
$azcred = Get-Credential
$profile = Connect-AzureRMAccount -Cred $azcred
$profile
```

The `$profile` variable output will contain some fields we'll need later such as `SubscriptionId` and `TenantId`.

### Create a Custom Role

We're going to create a custom role that is limited to modifying TXT records in whatever resource group it is assigned to. It will be based on the default `DNS Zone Contributor` role.

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

### (Optional) Create a Service Account

If you're using Posh-ACME from outside Azure and not using an existing access token, it is wise to create a service account specifically for modifying TXT records (e.g. App Registration). Ideally, the password should be long and randomized. The account will show up in the "App registrations" section of your Azure Active Directory.

```powershell
$svcPass = Read-Host Pass -AsSecureString
$svcAcct = New-AzureRmADServicePrincipal -DisplayName PoshACME -Password $svcPass
$svcAcct
```

The `ApplicationId` field in the variable output will be used later when assigning permissions and creating the credential object needed for the plugin.

### Assign Permissions To Resource Group

When you created the DNS zones, you had to assign them to a resource group. If they're all in the same Resource Group, this step will be much quicker. If not, you should either move them all to the same Resource Group or you'll have to repeat this step for each one.

```powershell
# get a reference to the Resource Group
$resGroup = Get-AzureRmResourceGroup "MyResourceGroup"
$resName = $resGroup.ResourceGroupName

# get a reference to the Role name we created earlier
$roleName = $role.Name
```

#### Service Account / App Registration

For an App Registration, we need to assign permissions to the Application ID which we can get from the `$svcAcct` variable we created earlier or the App's properties dialog in the Azure dashboard.

```powershell
$appID = $svcAcct.ApplicationId.ToString()
New-AzureRmRoleAssignment -ApplicationId $appID -ResourceGroupName $resName -RoleDefinitionName $roleName
```

#### Managed Service Identity (MSI)

When using a [Managed Service Identity (MSI)](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview), we need the security principal ID of the VM or Service to assign permissions to. This example will query a VM.

```powershell
$spID = (Get-AzureRMVM -ResourceGroupName '<VM Resource Group>' -Name '<VM Name>').identity.principalid
New-AzureRmRoleAssignment -ObjectId $spID -ResourceGroupName $resName -RoleDefinitionName $roleName
```

### (Optional) Get Existing Access Token

Any existing user, application, or managed service principal should work as long as it has been assigned permissions to managed DNS TXT records.

To use the context you are currently using with Powershell, use this function to retrieve the token.
```powershell
Function Get-AccessToken() {
    $tenantId = (Get-AzureRmContext).Tenant.Id

    $cache = (Get-AzureRmContext).tokencache
    $cacheItem = $cache.ReadItems() | Where-Object { $_.TenantId -eq $tenantId } | Select-Object -First 1
    return $cacheItem.AccessToken
}

$subId = (Get-AzureRmContext).Subscription.Id
$token = Get-AccessToken
$azParams = @{AZSubscriptionId=$subId;AZAccessToken=$token;}

```

To use the account you are currently logged in to with Azure CLI 2.0, use the following command to generate a token. Remember to use the correct subscription.
```powershell
# show all subscriptions - the one marked as "isDefault": true will be used to create the token
az account list
$token = (az account get-access-token --resource 'https://management.core.windows.net/' | ConvertFrom-Json).accessToken
```

To get a token for the MSI when running in a VM, Azure Function or App Service - please refer to the following documentation. Remember to pass in the correct resource uri: **https://management.core.windows.net/**

* [Getting a token for an MSI-enabled VM](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/how-to-use-vm-token)
* [Getting a token for an MSI-enabled App Service or Function](https://docs.microsoft.com/en-us/azure/app-service/app-service-managed-service-identity)

## Using the Plugin

All methods require specifying `AZSubscriptionId` which is the subscription that contains the DNS zones to modify.

### Explicit Credentials

Specify `AZTentantId` and `AZAppCred` which is the Azure AD tenant guid and user/app credentials. For an app registration, the username is the service account's `ApplicationId` guid and the password is whatever you originally set for it.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZTenantId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZAppCred=(Get-Credential)
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```

### Existing Access Token

Specify `AZAccessToken` using the value you retrieved earlier.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZAccessToken=$token;
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```

### Instance Metadata Service (IMDS)

Just add the `AZUseIMDS` switch.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZUseIMDS=$true;
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```
