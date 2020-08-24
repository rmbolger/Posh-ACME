# How To Use the Azure DNS Plugin

This plugin works against the [Azure DNS](https://azure.microsoft.com/en-us/services/dns/) provider. It is assumed that you already have an active subscription with at least one DNS zone, associated Resource Group, and an account with access to create roles and app registrations. The setup commands used in this guide will also make use of the [Az](https://www.powershellgallery.com/packages/Az/) module. But it is not required to use the plugin normally.

## Setup

This plugin has three distinct methods for authentication against Azure. The first involves specifying a Tenant ID and credentials for an account or app registration. The second requires an existing [OAuth 2.0 access token](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-protocols-oauth-code) which would generally be used for short lived services or environments where Azure authentication is being handled externally to the Posh-ACME module. The last is for systems running within Azure that have a [Managed Service Identity (MSI)](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview) and utilizes the [Instance Metadata Service (IMDS)](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service) to request an access token.

All methods require that the identity being used to authenticate has been given access to modify TXT records in the specified Azure subscription. If you have already done that, you can skip most of the following setup.

### Connect to Azure

Using an account with access to create roles and app registrations, connect to Azure with the following commands. We'll be saving the resulting Subscription and Tenant ID values for later.

```powershell
# On Windows, this will pop up a web-GUI to login with. On other OSes,
# it will ask you to open a browser separately with a code for logging in.
$az = Connect-AzAccount

# Save the subscription/tentant ID for later
$subscriptionID = $az.Context.Subscription.Id
$tenantID = $az.Context.Subscription.TenantId
```

### Create a Custom Role

We're going to create a custom role that is limited to modifying TXT records in whatever resource group it is assigned to. It will be based on the default `DNS Zone Contributor` role.

```powershell
$roleDef = Get-AzRoleDefinition -Name "DNS Zone Contributor"
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
$roleDef.AssignableScopes.Add("/subscriptions/$($az.Context.Subscription.Id)")

$role = New-AzRoleDefinition $roleDef
$role
```

### (Optional) Create a Service Principal / App Registration

If you're using Posh-ACME from outside Azure and not using an existing access token, it is wise to create a dedicated service principal limited to modifying TXT records. Service Principals are tied to App Registrations in Azure AD and creating the former will automatically create the latter (though it's technically possible to create them separately).

Service Principals are associated with one or more Credentials which can be password or certificated based. Certificates can be a bit trickier to setup particularly on non-Windows OSes, but Microsoft recommends them over passwords. We'll go over both methods below. Both also have configurable expiration values that default to 1 year and we'll be setting ours to 5 years, but you can choose whatever you like.

```powershell
$notBefore = Get-Date
$notAfter = $notBefore.AddYears(5)
```

#### Password Based Principal

The `New-AzADServicePrincipal` function will generate a password for us, so all we have to do is give it a name and specify our expiration dates. We'll also use `-SkipAssignment` to prevent the default functionality of giving it the Contributor role on the subscription.

```powershell
$sp = New-AzADServicePrincipal -DisplayName PoshACME -StartDate $notBefore -EndDate $notAfter -SkipAssignment
```

You'll use your new credential with either the `AZAppCred` plugin parameter or `AZAppUsername` and `AZAppPasswordInsecure` plugin parameters. The username is in the `ApplicationId` property and the password is in `Secret`. Here's how to save a reference to them for later.

```powershell
# For AZAppCred
$appCred = [pscredential]::new($sp.ApplicationId,$sp.Secret)

# For AZAppUsername and AZAppPasswordInsecure
$appUser = $appCred.UserName
$appPass = $appCred.GetNetworkCredential().Password
```

#### Certificate Based Principal on Windows

Before we can create a certificate based credential, we have to actually create a certificate to use with it. Self-signed certs are fine here because we're only using them to sign data and Azure just needs to verify the signature using the public key we will associate with the principal.

*Note: New-SelfSignedCertificate is only available on Windows 10/2016 or later. Check [this document](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-authenticate-service-principal-powershell) for instructions on earlier OSes.*

*Note: If you plan on using an existing certificate, make sure it is being stored using the legacy CSP called "Microsoft Enhanced RSA and AES Cryptographic Provider" that supports the SHA256 hashing algorithm. PowerShell doesn't yet support retrieving private key values from newer KSP based providers.*

```powershell
# Keep in mind that this certificate will be created in the current user's certificate
# store. If you intend to use it from another account, you will need to either create it
# there or export it and re-import it there.
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" `
    -Subject "CN=Azure App PoshACME" -HashAlgorithm SHA256 `
    -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
    -NotBefore $notBefore -NotAfter $notAfter

$certData = [System.Convert]::ToBase64String($cert.GetRawCertData())

$sp = New-AzADServicePrincipal -DisplayName PoshACME -CertValue $certData `
    -StartDate $cert.NotBefore -EndDate $cert.NotAfter
```

You'll use your new credential with the `AZAppUsername` and `AZCertThumbprint` plugin parameters. Here's how to save a reference to them for later.

```powershell
$appUser = $sp.ApplicationId.ToString()
$thumbprint = $cert.Thumbprint
```

#### Certificate Based Principal on non-Windows

Before we can create a certificate based credential, we have to actually create a certificate to use with it. As of PowerShell 6.2.3, the non-Windows support for .NET's certificate store abstraction is still not great. So we need to create the cert with OpenSSL and reference a PFX file directly rather than using the thumbprint value like on Windows. Self-signed certs are fine here because we're only using them to sign data and Azure just needs to verify the signature using the public key we will associate with the principal.

```powershell
# Depending on your OpenSSL config, this may prompt you for certificate details
# like Country, Organization, etc. None of the details matter for the purposes of
# authentication and can be set to anything you like.
openssl req -x509 -nodes -sha256 -days 1826 -newkey rsa:2048 -keyout poshacme.key -out poshacme.crt

# change the export password to whatever you want, but remember what it is so you can
# provide it as part of the plugin parameters
openssl pkcs12 -export -in poshacme.crt -inkey poshacme.key -CSP "Microsoft Enhanced RSA and AES Cryptographic Provider" -out poshacme.pfx -passout "pass:poshacme"

$cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new((Resolve-Path './poshacme.crt'))
$certData = [Convert]::ToBase64String($cert.GetRawCertData())

$sp = New-AzADServicePrincipal -DisplayName PoshACMELinux -CertValue $certData `
    -StartDate $cert.NotBefore -EndDate $cert.NotAfter

# (optional) delete the PEM files we don't need for plugin purposes
rm poshacme.crt poshacme.key

# IMPORTANT: Anyone who can read the crt/key or pfx files may be able to impersonate this
# service principal. So make sure to move and/or change permissions on the files so
# that only the process running Posh-ACME can read them.
```

You'll use your new credential with the `AZAppUsername`, `AZCertPfx`, and `AZPfxPass` plugin parameters. Here's how to save a reference to them for later.

```powershell
$appUser = $sp.ApplicationId.ToString()
# modify the path and/or password as appropriate
$certPfx = (Resolve-Path './poshacme.pfx').ToString()
$pfxPass = 'poshacme'
```

### Assign Permissions to the Service Principal

Now we'll tie everything together by assigning the service principal we created to the custom Role we created and the Resource Group that contains our DNS zones. If your zones are in more than one resource group, just repeat this for each one. If you used your own method for creating a service princpal, just use `Get-AzAdServicePrincipal` to get a reference to it first.

```powershell
# modify the ResourceGroupName as appropriate for your environment
New-AzRoleAssignment -ApplicationId $sp.ApplicationId -ResourceGroupName 'MyZones' `
    -RoleDefinitionName 'DNS TXT Contributor'
```

### (Optional) Using a Managed Service Identity (MSI)

When using a [Managed Service Identity (MSI)](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview), we need the security principal ID of the VM or Service to assign permissions to. This example will query a VM.

```powershell
# NOTE: The VM must have a managed identity associated with it for this to work
$spID = (Get-AzVM -ResourceGroupName '<VM Resource Group>' -Name '<VM Name>').Identity.PrincipalId
New-AzRoleAssignment -ObjectId $spID -ResourceGroupName 'MyZones' `
    -RoleDefinitionName 'DNS TXT Contributor'
```

In addition to the `AZSubscriptionId` plugin parameter that all auth methods must provide, the only plugin parameter you'll need is the `AZUseIMDS` switch.

### (Optional) Using An Existing Access Token

Any existing user, application, or managed service principal should work as long as it has been assigned permissions to manage DNS TXT records in the zones you're requesting certificates for.

Here's how to get the token for the context you are currently logged in with using with Powershell.

```powershell
$ctx = Get-AzContext
$token = ($ctx.TokenCache.ReadItems() | ?{ $_.TenantId -eq $ctx.Subscription.TenantId -and $_.Resource -eq "https://management.core.windows.net/" } |
    Select -First 1).AccessToken
```

Here's a similar method using Azure CLI 2.0.
```powershell
# show all subscriptions - the one marked as "isDefault": true will be used to create the token
az account list
$token = (az account get-access-token --resource 'https://management.core.windows.net/' | ConvertFrom-Json).accessToken
```

To get a token for the MSI when running in a VM, Azure Function or App Service - please refer to the following documentation. Remember to pass in the correct resource uri: **https://management.core.windows.net/**

* [Getting a token for an MSI-enabled VM](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/how-to-use-vm-token)
* [Getting a token for an MSI-enabled App Service or Function](https://docs.microsoft.com/en-us/azure/app-service/app-service-managed-service-identity)


## Using the Plugin

All authentication methods require specifying `AZSubscriptionId` which is the subscription that contains the DNS zones to modify. Password and Certificate based credentials also require `AZTenantId` which is the Azure AD tenant guid. Additional parameters are outlined in each section below.

### Password Credential

There are two parameter sets you can use with password based credentials. The first is used with `AZAppCred`, a PSCredential object, and can only be used from Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The second uses `AZAppUsername` and `AZAppPasswordInsecure` as plain text strings and can be used on any OS.

#### PSCredential (Windows or PS 6.2+)

PSCredential objects require a username and password. For a service principal, the username is the its `ApplicationId` guid and the password is whatever was originally set for it. If you've been following the setup instructions, you may have `$subscriptionID`, `$tenantID`, and `$appCred` variables you can use instead of the sample values below.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  AZTenantId='yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
  AZAppCred=(Get-Credential)
}

# issue a cert
New-PACertificate example.com -DnsPlugin Azure -PluginArgs $azParams
```

#### Plain text credentials (Any OS)

For a service principal, the username is its `ApplicationId` guid and the password is whatever was originally set for it. If you've been following the setup instructions, you may have `$subscriptionID`, `$tenantID`, `$appUser`, and `$appPass` variables you can use instead of the sample values below.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  AZTenantId='yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
  AZAppUsername='myuser'
  AZAppPasswordInsecure='xxxxxxxxxxxxxxxxxx'
}

# issue a cert
New-PACertificate example.com -DnsPlugin Azure -PluginArgs $azParams
```

### Certificate Credential

As of PowerShell 6.2.3 (November 2019), support for the certificate store abstractions only really works on Windows. So there are separate instructions for Windows and non-Windows OSes.

#### Windows Certificate

You'll need to specify the service principal username which is its `ApplicationId` guid and the certificate thumbprint value. If you've been following the setup instructions, you may have `$subscriptionID`, `$tenantID`, `$appUser`, and `$thumbprint` variables you can use instead of the sample values below.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  AZTenantId='yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
  AZAppUsername='zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz'
  AZCertThumbprint='1A2B3C4D5E6F1A2B3C4D5E6F1A2B3C4D5E6F1A2B'
}

# issue a cert
New-PACertificate example.com -DnsPlugin Azure -PluginArgs $azParams
```

#### Non-Windows Certificate

You'll need to specify the service principal username which is its `ApplicationId` guid, the path to the PFX file, and the PFX password. If you've been following the setup instructions, you may have `$subscriptionID`, `$tenantID`, `$appUser`, `$certPfx`, and `$pfxPass` variables you can use instead of the sample values below.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  AZTenantId='yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
  AZAppUsername='zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz'
  AZCertPfx='/home/certuser/poshacme.pfx'
  AZPfxPass='poshacme'
}

# issue a cert
New-PACertificate example.com -DnsPlugin Azure -PluginArgs $azParams
```

### Existing Access Token

Only the subscription guid and the access token you previously retrieved are required for this method.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  AZAccessToken=$token
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```

### Instance Metadata Service (IMDS)

Only the subscription guid and the `AZUseIMDS` switch are required for this method.

```powershell
$azParams = @{
  AZSubscriptionId='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  AZUseIMDS=$true;
}

# issue a cert
New-PACertificate test.example.com -DnsPlugin Azure -PluginArgs $azParams
```


## Workaround for Duplicate Public Zones

In rare cases, a subscription may have two or more public copies of the same zone in different resource groups. When this happens, the plugin will throw an error such as:

> 2 public copies of example.com zone found. Please use 'poshacme' tag on the live copy.

To workaround this problem, there are two main options. The easiest is to add an [Azure Tag](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags) called `poshacme` on the live copy of the zone. The tag value doesn't matter as long as the name is `poshacme`. The plugin will recognize this tag and ignore the other copies of the zone. (Note: This requires version 3.2.1 of the module or later)

The other solution is to remove permissions from the Azure account being used with Posh-ACME so it can only see the resource group that contains the live copy of the zone. But this may not be feasible depending on what else is in the resource group and what else the Azure account is being used for.
