# Using Persistent DNS Challenges

There are two main methods to utilize `dns-persist-01` with Posh-ACME. The recommended method is a 2 step process where you pre-provision the TXT records and then create your order with the `-DnsVariant dns-persist-01` parameter and no Plugin or PluginArgs parameters. There are a few variations of this method depending on who is responsible for publishing the DNS records and where they are publishing from. Alternatively, you can use a method very similarl to the standard `dns-01` challenge where you specify `-Plugin`, `-PluginArgs`, in addition to the new `-DnsVariant dns-persist-01` parameter and let the module provision the persisten records for you. But that somewhat defeats the purpose of having a persistent record because you still end up storing the Plugin and PluginArg details with the order.

!!! warning
    This guide assumes you are generally familiar with using Posh-ACME and DNS plugins and have already at least configured an ACME server and setup an ACME account. If not, start with the [Tutorial](../Tutorial/index.md) and then come back.

!!! note
    As of October 2026, Google is the only free public CA supporting this challenge type in production, but the implementation is currently based on draft 01 of the spec. Posh-ACME supports draft 02 which uses an incompatible TXT record format. However, the Advanced parameter set of [Publish-DnsPersistChallenge](../Functions/Publish-DnsPersistChallenge.md) can still be used to publish draft 01 compatible TXT records and the rest of the cert request workflows work against draft 01 servers.
    
    Let's Encrypt has a `dns-persist-01` implementation on their staging endpoint based on an earlier draft which is largely compatible with draft 01. They have [stated](https://letsencrypt.org/2026/02/18/dns-persist-01) their goal for production rollout is some time in 2026. But that will realistically depend on how quickly the spec approaches finalization and the finalized implementation will likely be based on draft 02 or later. The self-hosted ACME test server, [Pebble](https://github.com/letsencrypt/pebble), also currently has support for draft 01.

!!! warning
    The spec for this challenge type is still in active development and may still change in such a way that forces breaking changes in the current functionality. I will not be doing major version upgrades for breaking changes specifically surrounding dns-persist-01 support. Please be mindful of the changelog if you attempt to use the new functionality for your own production certs. I will attempt to remain as compatible as possible with the implementations of the free ACME CAs whenever they go into production.

## Pre-Provisioning

Pre-provisioning is a bit more work up front, but you should only have to do it once unless you set an expiration with `-PersistUntil` or your ACME account key is rotated. Both require updating the record value with new data to continue using them. Creating the persistent TXT records can be done either from the same system where Posh-ACME is running from or an entirely different system. It's a bit easier if the secondary system has a copy of Posh-ACME, but not required.

Each unique name published using the variations below will have a persistent record published for it. If there are wildcard names, the `policy=wildcard` flag will be added to that record automatically. This is necessary for the wildcard validations to succeed. You can prevent the automatic addition with the `-NoAutoWildcard` switch, but it will then skip creating the record for that name since it wouldn't work for validation. Alternatively, you may use the `-AllowWildcard` switch to add the wildcard flag to all of the records even if they're not technically needed. Just be aware that the `policy=wildcard` flag authorizes all nested sub-domains for that FQDN and ACME account.

### Publish from Pending Order

This method assumes you're publishing from the same Posh-ACME system you're requesting certs from. You'll need to have an ACME server already configured with `Set-PAServer` and an account already created with `New-PAAccount`.

First, create a barebones pending order with the `-DnsVariant dns-persist-01` parameter.

```powershell
$certNames = 'example.com','www.example.com'
New-PAOrder $certNames -DnsVariant dns-persist-01 -Verbose
```

Then, prep your plugin args and publish your records using the order. The plugin related parameters are only used for this command and not saved to your Posh-ACME config.

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
Get-PAOrder | Publish-DnsPersistChallenge -Plugin FakeDNS -PluginArgs $pArgs -Verbose
```

!!! warning
    If you are running against a CA like Google that is using draft 01 or earlier of the spec, the publish step using the pending order won't work because it requires fields in the server and challenge objects that may not exist. See the Advanced Publishing section for a workaround.

### Publish using Account Details

This method still requires a Posh-ACME installation, but doesn't need to be the same system you request certs from as long as you're referencing the same ACME account from both systems. There are two variations and both require an ACME server configured with `Set-PAServer`. The first also requires a local Posh-ACME account created with `New-PAAccount`. The second only requires output from the system with the ACME account.

!!! warning
    If you are running against a CA like Google that is using draft 01 or earlier of the spec, neither of these methods will work because draft 02 TXT records that get published are incompatible with draft 01 implementations. See the Advanced publishing section for a workaround.

#### Local Account

Prep your domain list and plugin args and publish your records using the current account.

```powershell
$pubParams = @{
    Domain = 'example.com','www.example.com'
    Account = (Get-PAAccount)
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    Verbose = $true
}
Publish-DnsPersistChallenge @pubParams
```

#### Remote Account

From the remote system with the ACME account configured, get the account location and thumbprint values.

```powershell
Get-PAAccount | Select-Object thumbprint,location
```

From the local system, prep your domain list and plugin args and publish your records using the details from the remote system.

```powershell
$pubParams = @{
    Domain = 'example.com','www.example.com'
    # use the location value from the remote system
    AccountUri = 'https://ca.example/acct/123'
    # use the thumbprint value from the remote system
    KeyThumbprint = 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs'
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    Verbose = $true
}
Publish-DnsPersistChallenge @pubParams
```

### Advanced Publishing

Users running against draft 02 or newer CAs shouldn't generally need to use this method. But it can be useful if the spec changes and you need more granular control over the TXT record values. This method can also be used to publish draft 01 compatible records for use with older implementations like the one Google uses.

The Advanced parameter set for [Publish-DnsPersistChallenge](../Functions/Publish-DnsPersistChallenge.md) has only one required parameter besides the standard domain list which is `-HashedAccountUri`. It is the string that ends up in the TXT record as `accountUri=<value>`. For draft 02+, use the `HashedAccountUri` property from [Get-DnsPersistAccountUri](../Functions/Get-DnsPersistAccountUri.md), which also returns a matching `Domain` property for direct pipeline binding. The other semi-required parameter is `-IssuerDomainName`. On a draft 02+ CA, it will be auto-populated from the `issuerDomainNames` field of the directory meta object if not explicitly set. If you're working against a draft 01 CA or don't have a server selected, it is required and will throw an error if not included. The rest of the optional parameters are similar to the other parameter sets for things like plugin details, wildcard handling, and optional expiration.

Here is an example of using advanced publishing with a draft 02 compatible CA.

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
# AccountUri and KeyThumbprint can be used instead of a local account.
'example.com','*.example.org' | Get-DnsPersistAccountUri -Account (Get-PAAccount) |
    Publish-DnsPersistChallenge -Plugin FakeDNS -PluginArgs $pArgs -Verbose
```

For a draft 01 CA, the HashedAccountUri must be set to the actual account URI value. You'll also need to either query an issuer from the `caaIdentities` list or just specify one manually. It will generally match the domain name value used in a CAA record.

```powershell
# use when publishing from the same system the cert is requested from
$issuer = (Get-PAServer).meta.caaIdentities[0]  # or any value from the list
$accountUri = (Get-PAAccount).location

# use when publishing from a different system (copy/paste from the cert system)
$issuer = 'ca.example'
$accountUri = 'https://ca.example/acct/123'

$pubParams = @{
    Domain = 'example.com','www.example.com'
    HashedAccountUri = $accountUri
    IssuerDomainName = $issuer
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    Verbose = $true
}
Publish-DnsPersistChallenge @pubParams
```

### Obtain Cert Using Pre-Provisioned Records

Ensure all of your authoritative DNS servers are serving the necessary persistent records and then run `New-PACertificate` with any subset of domains you published records for.

```powershell
New-PACertificate 'example.com','www.example.com' -DnsVariant dns-persist-01 -Verbose
```

## Auto-provisioning with Saved PluginArgs

In addition to the plugin-specific PluginArgs values you're using, there is a new shared parameter that tells the module to auto-provision the persistent records called `PublishPersist`. Set it to `$true` in your PluginArgs hashtable and then proceed normally with your certificate provisioning commands while also using the `-DnsVariant dns-persist-01` parameter like this:

```powershell
$certNames = 'example.com','www.example.com'
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    PublishPersist = $true
}
New-PACertificate $certNames -Plugin FakeDNS -PluginArgs $pArgs -DnsVariant dns-persist-01
```

This will auto-create the necessary persistent records if they don't exist. But it will not remove them like it normally does with `dns-01` after the order is complete. It will also continue to try and create the persistent records during renewals if they no longer exist for whatever reason.

## Migrate an Existing Order from dns-01

### Check if dns-persist-01 is supported

Before changing any existing orders and publishing persistent records, double check whether your ACME CA actually supports the spec first.

Create temporary throw-away order and check the challenge object.

```powershell
# create a pending order
New-PAOrder example.com

# check for dns-persist-01 challenges
Get-PAOrder | Get-PAAuthorization | Select -Expand challenges | ?{ $_.type -eq 'dns-persist-01' }
# if nothing is returned here, dns-persist-01 is not supported yet

# delete the throwaway order
Get-PAOrder | Remove-PAOrder -Force
```

If the challenge type is supported, check whether it is draft 01 or 02+.

```powershell
# list the directory meta fields
Get-PAServer -Refresh | Select -Expand meta

# draft 02+ must have
# - "issuerDomainNames" list field
# - "accountHashPrefix" string field

# any server missing those two fields is draft 01 or earlier
```

### Publish Necessary Records

For draft 02+ servers, use any of the methods above to publish compatible records. For draft 01 servers, use the Advanced Publishing instructions specifically for draft 01. Don't forget to ensure all of your authoritative DNS servers are now serving the necessary persistent records for the order you will be migrating.

### Migrate the Order

Make sure the order you're migrating is selected and then do the following.

```powershell
# empty the args for the old plugin set
# (don't combine this with the next command or the args won't clear)
Set-PAOrder -PluginArgs @{}

# set the plugin back to Manual and the DnsVariant setting
Set-PAOrder -Plugin Manual -DnsVariant dns-persist-01
```

Then continue renewing the order as you normally would. If you're calls to `New-PACertificate` instead of `Submit-Renewal`, make sure you update your script parameters to exclude the `-Plugin` and `-PluginArgs` parameters and include the `-DnsVariant dns-persist-01` parameter.

## Updating or Removing Persistent Records

There are a few reasons you may update or replace your persistent validation records.

- Your ACME account key changes due to a rollover.
  - Because the record data is partially computed from the account key, changing that key changes what gets computed. The draft 02 spec technically requires CAs to continue allowing validation against records computed from former account keys, but it also strongly suggests clients re-publish new records after a rollover for "operational hygiene and auditing".
- Your ACME account is deactivated or otherwise lost.
  - Account deactivation is non-reversible. If it happens on purpose or due to compromise, all of your existing records immediately become invalid and require re-publishing from a new account.
- You used a PersistUntil value that has expired or will expire soon.
  - An expired record won't validate. You'll want to unpublish the old record and republish a new record with an updated PersistUntil value before the old record expires.

There are two variations on how to unpublish a persistent record using Posh-ACME.

### Use the same Publish parameters with Unpublish

Whatever parameters you originally used to publish the record with `Publish-DnsPersistChallenge` can be used with `Unpublish-DnsPersistChallenge` with the following caveats.

- The `FromOrder` parameter set may not work if the order is expired.
- The `FromOrder` parameter set may not work if the CA does not return the same set of authorization data for a previously valid order.
- The `PreProvision` parameter set where you pass the ACME account object will not find the correct record to unpublish if the account key has been rotated. Use the `PreProvisionExplicit` parameter set instead with `-KeyThumbprint` set to the previous value.
- If you created the record with a `-PersistUntil` value that was based on a date/time relative to "now", you can't use that same calculation because the new "now" is different than the old "now". This is why it is highly recommended to use UTC date-only values such as `'2027-04-01Z'`.

### Pipe Get-PublishedPersistChallenge to Unpublish

The `Get-PublishedPersistChallenge` command returns the record data for all records published from the entire local config. You can filter the results to the records you want to unpublish, and pipe them to `Unpublish-DnsPersistChallenge` along with the necessary plugin parameters.

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
Get-PublishedPersistChallenge |
Where-Object { $_.Domain -eq 'example.com' } |
Unpublish-DnsPersistChallenge -Plugin FakeDNS -PluginArgs $pArgs -Verbose
```

The data returned by `Get-PublishedPersistChallenge` may include `Domain`, `HashedAccountUri`, `IssuerDomainName`, `AllowWildcard`, `PersistUntil`, `FromAccountUri`, and `FromAccountThumbprint` which can all be filtered against. However, `FromAccountUri` and `FromAccountThumbprint` will be empty for any records published using the Advanced parameter set because they aren't known when using that parameter set.
