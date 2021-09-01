# Using DNS Challenge Aliases

## Background

There are two relatively common issues that come up when people try to automate ACME certs using DNS challenges. The first is that the DNS provider hosting the zone either doesn't have an API or the ACME client doesn't have a plugin to support it. The second is that for security reasons, the business may not want to save API credentials for their critical DNS zone on an internet-facing web server.

The workaround for both of these involves using a [CNAME record](https://support.dnsimple.com/articles/cname-record/) to redirect challenge requests to another DNS zone. When the ACME server goes to validate the challenges, it will follow the CNAME and check the challenge token from the redirected record. If the original problem was no API or no plugin, you'd put the redirected zone on a provider with an API and a supported plugin. If the original problem was security related, you'd make the redirected zone a less important one. The downside is the extra manual step required to add the CNAME for each new cert or name in a cert. But you only have to do that once ever for each name.

## Creating CNAMEs

So how do we do that? First, you have to understand how the ACME protocol chooses what record to query for each name in a certificate. Non-wildcard names have `_acme-challenge.` prepended to them. Wildcard names use the same prefix but it replaces the `*.` prefix. So for example:

Cert Name                 | Challenge Record
---------                 | ----------------
example.com               | _acme-challenge.example.com
*.example.com             | _acme-challenge.example.com
sub1.example.com          | _acme-challenge.sub1.example.com
*.sub1.example.com        | _acme-challenge.sub1.example.com
www.sub1.sub2.example.com | _acme-challenge.www.sub1.sub2.example.com

You may have noticed that a wildcard name and a non-wildcard for the same root domain have the same challenge record. That's not a mistake and the ACME server does actually expect to get two different values for the same TXT record. What it means for you though is that you only have one CNAME to create for both types of names.

Where do you point the CNAMEs to? It doesn't really matter as long as the ACME server can query it from the Internet and Posh-ACME can create the necessary records there. Some choose to use the same `_acme-challenge.` prefix for clarity. Some use a different prefix because their provider doesn't allow names to start with a `_` character. Some just point all of their CNAMEs to the exact same place. Examples:

Challenge Record            | CNAME Target
----------------            | ------------
_acme-challenge.example.com | _acme-challenge.example.net
_acme-challenge.example.com | acme.example.net
_acme-challenge.example.com | _acme-challenge.validation.example.net
_acme-challenge.example.com<br>_acme-challenge.sub1.example.com<br>_acme-challenge.sub2.example.com | acme.example.net
_acme-challenge.example.com | example.net

!!! warning
    Don't point too many CNAMES at the same target. Let's Encrypt's ACME implementation can only deal with DNS responses [up to 4096 bytes](https://github.com/letsencrypt/boulder/pull/3467) which is roughly 60-70 TXT records depending on your DNS server and query parameters. If your record is too big, the validations will fail.

## Testing

You should verify your CNAME was created correctly before you try and use it. If you're inside a business with a split-horizon DNS infrastructure, you might need to explicitly query a public external resolver like CloudFlare's 1.1.1.1. However, some modern firewalls can be configured to prevent this ability. So make sure you can successfully query a known-good external record first. There are also web-based resolvers such as https://www.digwebinterface.com/ if necessary.

```doscon
C:\>nslookup -q=CNAME _acme-challenge.example.com. 1.1.1.1
Server:  1dot1dot1dot1.cloudflare-dns.com
Address:  1.1.1.1

Non-authoritative answer:
_acme-challenge.example.com  canonical name = acme.example.net
```

## Using the Challenge Alias

Now that your CNAMEs are all setup, you just have to add one more parameter to your certificate request command, `-DnsAlias`. It works just like `-Plugin` as an array that should have one element for each domain in the request. But if all of your CNAMEs point to the same place, you can just specify the alias once and it will use that alias for all the names.

```powershell
New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact 'admin@example.com' `
    -Plugin Route53 -PluginArgs $pArgs -DnsAlias acme.example.net -Verbose
```
