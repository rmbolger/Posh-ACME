# DNS Challenge Variants

## Background

Recent versions of Posh-ACME have added experimental support for two ACME protocol extensions currently in draft state that add new DNS-based challenge types.

- [ACME DNS Labeled With ACME Account ID Challenge](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-account-label) (a.k.a `dns-account-01`)
- [ACME Challenge for Persistent DNS TXT Record Validation](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-persist/) (a.k.a `dns-persist-01`)

The first, `dns-account-01`, is intended to solve the `dns-01` problem where multiple entities (servers, CDNs, hosting providers, etc) legitimately need to provision certs for the same name, but only one can be delegated control of the associated `_acme-challenge` TXT record at a time. The new challenge type changes the FQDN of the TXT record to include an additional label based on the ACME account. Everything else is the same as `dns-01` including the need to provision new TXT record values at every renewal.

The second, `dns-persist-01`, is a bit more exciting and may end up becoming the new most popular challenge type because of the operational hassles it removes. It essentially allows an ACME user to provision a persistent TXT record that no longer needs to updated at every renewal. The record theoretically remains valid forever unless the user chooses to limit its validity with an expiration date or something else changes with the ACME account that would necessitate updating the record. It's a huge operational win because it removes the need to store API credentials for your DNS server with your ACME client.

!!! note
    At the time of this writing, no free public CAs support either of these new challenge types in production. But both Let's Encrypt and Google have `dns-persist-01` implementations on their staging endpoints based on early drafts. Let's Encrypt has [stated](https://letsencrypt.org/2026/02/18/dns-persist-01) their goal for production rollout is some time in 2026. But that will realistically depend on how quickly the spec is finalized. The self-hosted ACME test server, [Pebble](https://github.com/letsencrypt/pebble), also has support for both challenge types.

!!! warning
    This guide assumes you are generally familiar with using Posh-ACME and DNS plugins and have already at least configured an ACME server and setup an ACME account. If not, start with the [Tutorial](../Tutorial) and then come back.

## Using dns-account-01

Using `dns-account-01` with Posh-ACME is almost exactly like using it with `dns-01`. All the same DNS plugins work as they normally do. You just need to use the new `-DnsVariant dns-account-01` parameter in your various calls to these functions and the module will take care of the rest.

- New-PACertificate
- New-PAOrder
- Set-PAOrder
- Publish-Challenge
- Unpublish-Challenge

So for example:

```powershell
$certNames = 'example.com','www.example.com'
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
New-PACertificate $certNames -Plugin FakeDNS -PluginArgs $pArgs -DnsVariant dns-account-01
```

The TXT record that gets created will have an FQDN such as `_hidldt6bzfka7fw3._acme-challenge.example.com` where that random-looking prefix is a value generated from your ACME account URI. If you need to delegate control of the TXT record with a CNAME or generally want to know what the FQDN will be in advance, you can use the following to return the label after creating an ACME account.

```powershell
Get-PAAccount | Get-DnsAcctLabel
```

## Using dns-persist-01

There are two main methods to utilize `dns-persist-01` with Posh-ACME. The recommended method is a 2 step process where you provision the TXT records in advance and then create your order with the `-DnsVariant dns-persist-01` parameter and no Plugin or PluginArgs parameters. Alternatively, you can do it very similarly to a standard `dns-01` challenge where you specifiy `-Plugin`, `-PluginArgs`, in addition to the new `-DnsVariant dns-persist-01` parameter and let the module provision the persisten records for you. But that sort of defeats the purpose of having a persistent record because you still end up storing the Plugin and PluginArg details with the order.

### Pre-provisioning

Pre-provisioning is a bit more work up front, but you only have to do it once. Creating the persistent TXT records can be done either on the same system where the cert will be deployed or an entirely different system. From the same system is a bit easier, but we'll go through both.

#### Publish from Deployment System

First, create a barebones pending order with the necessary details.

```powershell
$certNames = 'example.com','www.example.com'
New-PAOrder $certNames -DnsVariant dns-persist-01
```

Then, prep your plugin args and publish your records using the order.

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
Get-PAOrder | Publish-DnsPersistChallenge -Plugin FakeDNS -PluginArgs $pArgs -Verbose
```

Each unique name in the order will have a persistent record published for it. If you're using any wildcard names, you'll also need to include the `-AllowWildcard` switch which adds additional data to the TXT record authorizing the CA to provision wildcard names. Just remember that the wildcard tag will be added to all of the persistent records for the order even if they're not technically needed. If you want full control over the contents of the records, you'll need to use the explicit parameter set as in the next section.

#### Publish from Separate System

If you want to publish your persistent records on a separate system where you don't have an existing PAOrder object to reference, you'll need to use a different paraemter set with `Publish-DnsPersistChallenge` that requires specifying all of the necessary fields for the record. This can also be useful even on the same system if you want to customize the records beyond what the function will normally create from an order.

First, gather the prerequisite data. You'll need an **Issuer Domain Name** and **Account Uri** value. The Issuer Domain can usually be found in the CA's directory metadata. The Account URI is the `location` field on your PAAccount object. Use the following code to grab them from the deployment system where your ACME account exists.

```powershell
# from the deployment system
$issuer = (Get-PAServer).meta.caaIdentities[0]
$accountUri = (Get-PAAccount).location

# or copy/pasted from the deployment system
$issuer = 'ca.example.org'
$accountUri = 'https://acme.ca.example.org/acct/12345'
```

!!! note
    Not all CAs publish the `caaIdentities` field in their directory metadata. If you get an error querying it like this or the value is empty, you'll need to obtain the value from your CA directly. It's the same value that would go into a CAA record and they usually publish it on their website.

Then, prep your parameters and publish the records.

```powershell
$publishParams = @{
    Domain = 'example.com','www.example.com'
    AccountUri = $accountUri
    IssuerDomainName = $issuer
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    Verbose = $true
}
Publish-DnsPersistChallenge @publishParams
```

If you're using wildcard names, don't forget to include the `-AllowWildcard` switch which adds additional data to the TXT record authorizing the CA to provision those wildcard names.

#### Obtain Cert Using Pre-Provisioned Records

Ensure that the pre-provisioned records have had a chance to sync with all authoritative nameservers for your domain(s). Then, create a barebones cert request and everything should just work from now on.

```powershell
New-PACertificate 'example.com','www.example.com' -DnsVariant dns-persist-01 -Verbose
```

### Auto-provisioning with PluginArgs

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
