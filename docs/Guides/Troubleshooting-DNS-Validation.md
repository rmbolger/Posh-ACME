# Troubleshooting DNS Validation

## Overview

One of the more common problems using DNS challenge validation with ACME is when the server thinks your TXT records either don't exist or are invalid. There are a number of reasons why this might be the case and in this guide, we'll go over some of the possibilities. But first, let's review how to query TXT records.

## Querying TXT records

`nslookup` is the primary tool most people use to do DNS queries from Windows because it's installed by default and available on every Windows OS since basically forever. PowerShell has `Resolve-DnsName` but only since Windows 8/2012. So we'll focus on `nslookup` for now.

```
C:\>nslookup -q=txt _acme-challenge.example.com.
```

**Don't forget the final `.` on the domain name.**

This is the basic command that will query your local DNS server. But it's usually wise to specifically query a public DNS resolver like Google (8.8.8.8) or CloudFlare (1.1.1.1) in case you're in a [split-brain](https://en.wikipedia.org/wiki/Split-horizon_DNS) DNS environment. However, some businesses are starting to deploy firewalls that block outbound DNS requests like this. So make sure you are able to query a known good record before tearing your hair out troubleshooting the record you're having trouble with. Here's how to explicitly query an external resolver.

```
C:\>nslookup -q=txt _acme-challenge.example.com. 1.1.1.1
```

If the query was successful, the output might look something like this:

```
Server:  1dot1dot1dot1.cloudflare-dns.com
Address:  1.1.1.1

Non-authoritative answer:
_acme-challenge.example.com    text =

        "asdfa7sdcv6qn4klav7127134"
```

Otherwise, it will be more like this:
```
Server:  1dot1dot1dot1.cloudflare-dns.com
Address:  1.1.1.1

*** 1dot1dot1dot1.cloudflare-dns.com can't find _acme-challenge.example.com: Non-existent domain
```

## DNS Propagation Delays

In many environments, the DNS server you are adding records to is not the same server that the Internet is sending queries to. Depending on the server and the DNS architecture, there may be both database replication delays and DNS zone transfer delays to slave servers.

By default, Posh-ACME sleeps for 2 minutes after writing TXT records for a certificate before it asks the ACME server to validate them. But 2 minutes might not be long enough for your particular environment. In that case, use the `-DnsSleep` parameter to modify the default sleep time. It takes a value in seconds. So if you needed 5 minutes, you'd use `-DnsSleep 300`.

And rather than just blindly increasing the delay when you're having a problem, it's a good idea to actually measure instead.

- Manually create a record
- Start a timer
- Query the record every few seconds until you see the change
- Make a note of the total time
- Add a 30 second buffer or so and use that value for `-DnsSleep`

If you never see the change, it's possible you're having a different problem.

## Internal vs External DNS

Particularly in business environments, it is common to have a [split-brain](https://en.wikipedia.org/wiki/Split-horizon_DNS) DNS architecture which basically means there might be two different "views" of a particular zone, one internal and one external. The internal view might resolve `example.com` to an internal IP like `10.0.0.50`. But the external view for the same name might resolve to public IP like `203.0.113.50`.

Make sure that you only add your DNS challenge TXT records to the External view because that's the one the ACME server will be able to see.

## CAA Record Issues

CAA is a relatively new type of DNS record that allows site owners to specify which Certificate Authorities (CAs) are allowed to issue certificates containing their domain names. Let's Encrypt, being a well behaved CA, tries to validate CAA records before issuing a certificate for a domain. So if you have a CAA record that is not correctly set to to allow Let's Encrypt, your challenge validation would fail. But there are a number of reasons why it might fail even if you are not using CAA records in your zone. Check Let's Encrypt's [CAA document](https://letsencrypt.org/docs/caa/) for more information.
