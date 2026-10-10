# DNS Challenge Variants

## Background

Recent versions of Posh-ACME have added experimental support for two ACME protocol extensions currently in draft state that add new DNS-based challenge types.

- [ACME DNS Labeled With ACME Account ID Challenge](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-account-label) (a.k.a `dns-account-01`)
- [ACME Challenge for Persistent DNS TXT Record Validation](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-persist/) (a.k.a `dns-persist-01`)

The first, `dns-account-01`, is intended to solve the `dns-01` problem where multiple entities (servers, CDNs, hosting providers, etc) legitimately need to provision certs for the same name, but only one can be delegated control of the associated `_acme-challenge` TXT record at a time. The new challenge type changes the FQDN of the TXT record to include an additional label based on the ACME account. Everything else is the same as `dns-01` including the need to provision new TXT record values at every renewal.

The second, `dns-persist-01`, is a bit more exciting and may end up becoming the new most popular challenge type because of the operational hassles it removes. It allows an ACME user to provision a persistent TXT record that no longer needs to updated at every renewal. The record theoretically remains valid forever unless the user chooses to limit its validity with an expiration date or the account key is rotated which both require updating the record value. It's a huge operational win because it removes the need to store API credentials for your DNS server with your ACME client.

!!! warning
    This guide assumes you are generally familiar with using Posh-ACME and DNS plugins and have already at least configured an ACME server and setup an ACME account. If not, start with the [Tutorial](../Tutorial/index.md) and then come back.

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

!!! note
    As of October 2026, Google is the only free public CA supporting this challenge type in production. The self-hosted ACME test server, [Pebble](https://github.com/letsencrypt/pebble), also has support.

## Using dns-persist-01

Please see the dedicated [Using Persistent DNS Challenges](Using-Persistent-DNS-Challenges.md) guide.
