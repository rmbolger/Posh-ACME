title: (Advanced) Custom Challenge Validation

# Custom Challenge Validation

## Intro

The beauty of the ACME protocol is that it's an [open standard](https://tools.ietf.org/html/rfc8555). And while Posh-ACME primarily targets users who want to avoid understanding all of the protocol complexity, it also exposes functions that allow you to do things a bit closer to the protocol level than just running `New-PACertificate` and `Submit-Renewal`. This can enable more advanced automation scenarios such as supporting challenge types that the module doesn't directly support yet or responding to authorization challenges in a way not directly supported by existing plugins. This guide will walk through the ACME certificate request process and demonstrate how to manage the validation of authorization challenges.

At a high level, the ACME conversation looks more or less like this:

- Create an account
- Create a certificate order
- Prove control of the "identifiers" (DNS names or IP addresses) in the requested cert by answering challenges.
- Finalize the order by submitting an certificate request (CSR)
- Download the signed certificate and chain

!!! warning
    IP Address identifiers ([RFC 8738](https://tools.ietf.org/html/rfc8738)) are supported by Posh-ACME. But they're not yet supported by any ACME-compatible public certificate authorities that I'm aware of. If you want to test them, you'll have to use [Pebble](https://github.com/letsencrypt/pebble).

If you're curious about what's going on under the hood during this guide, add `-Verbose` to your commands or run `$VerbosePreference = 'Continue'`. If you really want to get deep, you can also turn on debug logging by running `$DebugPreference = 'Continue'` which will also display the raw JSON requests and responses. The defaults for both of those preferences are `SilentlyContinue` if you want to change them back later.

## Server Selection

While testing code, you should **not** use the production Let's Encrypt server. The staging server is the easiest alternative, but still has some rate limits that you can run afoul of if your code goes crazy. There is also [Pebble](https://github.com/letsencrypt/pebble) which is a tiny ACME server you can self-host and is built for testing code against. For simplicity, we'll select the Let's Encrypt staging server.

```powershell
Set-PAServer LE_STAGE
```

## Account Setup

Requesting a certificate always starts with creating an account on the ACME server which is basically just a public/private key pair that is used to sign the protocol messages you send to the server along with some metadata like one or more email addresses to send expiration notifications to. If you've been previously using the module against the staging server, you likely already have an account. If so, you can either skip this section or create a second account which is also supported.

```powershell
New-PAAccount -AcceptTOS -Contact 'me@example.com'
```

!!! warning
    If you're using Pebble as your ACME server, it doesn't save accounts or order details when you shut it down. So you'll have to re-create accounts and orders if you exit and restart it.

## Create an Order

The only required parameter for a new order is the set of names you want included in the certificate. Optional parameters include things like `-KeyLength` to change the private key type/size, `-Install` which tells Posh-ACME to automatically store the signed cert in the Windows certificate store *(requires local admin)*, and `-PfxPass` which lets you set the decryption password for the certificate PFX file. If we were using plugins, this is also where you could set which plugin to use and the parameters associated with it.

In this example, we'll create a typical wildcard cert that contains a root domain and the wildcard version of it. Keep in mind that wildcard names [require using DNS challenge validation](https://community.letsencrypt.org/t/acme-v2-and-wildcard-certificate-support-is-live/55579). So if you're testing HTTP challenge validation, either leave that one out or add a different non-wildcard name.

```powershell
$domains = 'example.com','*.example.com'
New-PAOrder $domains
```

Assuming you didn't use names that were previously validated on this account, you should get output that looks something like this where the status is `pending`. If the status is `ready`, create an order with different names that haven't been previously validated.

```
MainDomain  status  KeyLength SANs            OCSPMustStaple CertExpires Plugin
----------  ------  --------- ----            -------------- ----------- ------
example.com pending 2048      {*.example.com} False                      {Manual}
```

## Authorizations and Challenges

The distinction between an order, authorization, and challenge can be confusing if you're not familiar with the ACME protocol. So let's clarify first. An order is a request for a certificate that contains one or more "identifiers" (a name like `example.com`). Each identifier in an order has an authorization object associated with it that indicates whether the account that created the order is authorized to get a cert for that name. New authorizations start in a pending state awaiting the client to complete a challenge associated with that authorization. Each authorization can have multiple different challenges (DNS, HTTP, ALPN, etc) that indicate the different methods the ACME server will accept to prove ownership of the name. You only need to complete one of the offered challenges in order to satisfy an authorization.

!!! note
    Different types of identifiers may only allow a subset of challenge types. For instance, wildcard DNS names can only be validated by a DNS challenge and IP addresses can only be validated by HTTP or ALPN challenges.

`Get-PAAuthorization` can be used with the output of `Get-PAOrder` to retrieve the current set of authorizations (and their challenges) for an order. So lets put those details into a variable and display them.

```powershell
$auths = Get-PAOrder | Get-PAAuthorization
$auths
```

This should give an output that looks something like this. The first status column is the overall status of the authorization. The last two columns are the status of the `dns-01` and `http-01` challenges. Normally the challenge specific details are buried a bit deeper in a `challenges` property, but Posh-ACME tries to help by surfacing the commonly used challenge details on the root object. Notice also how the wildcard name has no `HTTP01Status` because it was not offered as a valid challenge type for that identifier.

```
fqdn          status  Expires               DNS01Status HTTP01Status
----          ------  -------               ----------- ------------
example.com   pending 12/24/2020 7:14:33 PM pending     pending
*.example.com pending 12/24/2020 7:14:33 PM pending
```

Let's take a look at the full details of one of the authorization objects by running `$auths[0] | fl`. You should get an output like this:

```
identifier   : @{type=dns; value=example.com}
status       : pending
expires      : 2020-12-25T16:52:23Z
challenges   : {@{type=dns-01; status=pending; url=https://acme-staging-v02.api.letsencrypt.org/acme/challenge/<AUTH_ID>/<DNS_CHAL_ID>; token=<DNS_TOKEN>},
               @{type=http-01; status=pending; url=https://acme-staging-v02.api.letsencrypt.org/acme/challenge/<AUTH_ID>/<HTTP_CHAL_ID>; token=<HTTP_TOKEN>},
               @{type=tls-alpn-01; status=pending; url=https://acme-staging-v02.api.letsencrypt.org/acme/challenge/<AUTH_ID>/<ALPN_CHAL_ID>; token=<ALPN_TOKEN>}}
DNSId        : example.com
fqdn         : example.com
location     : https://acme-staging-v02.api.letsencrypt.org/acme/authz/<AUTH_ID>
DNS01Status  : pending
DNS01Url     : https://acme-staging-v02.api.letsencrypt.org/acme/challenge/<AUTH_ID>/<DNS_CHAL_ID>
DNS01Token   : <DNS_TOKEN>
HTTP01Status : pending
HTTP01Url    : https://acme-staging-v02.api.letsencrypt.org/acme/challenge/<AUTH_ID>/<HTTP_CHAL_ID>
HTTP01Token  : <HTTP_TOKEN>
```

For this identifier, the ACME server has offered all three challenge types: `http-01`, `dns-01`, and `tls-alpn-01`. In addition to the type, each challenge contains a `status`, `url` and `token` property. For HTTP and DNS challenges, these can also be read from the root authorization object using the `HTTP01xxx` and `DNS01xxx` properties. We'll go over how to use the tokens in the next couple sections about publishing challenges.


## Publishing an HTTP Challenge

For an HTTP challenge, the ACME server must be able send an HTTP GET request to a particular URL **on port 80** and receive a [key authorization](https://tools.ietf.org/html/rfc8555#section-8.1) value which is based on the token value in the challenge and the public key thumbprint of your account key. You can build the URL using the following template:

```powershell
$url = 'http://{0}/.well-known/acme-challenge/{1}' -f $auths[0].DNSId,$auths[0].HTTP01Token
```

!!! note
    Most ACME servers will follow HTTP 3xx redirect responses, but the initial request will always be non-TLS to port 80. So you must not block port 80 on your web server if you want to use HTTP challenges.

The key authorization can be generated using `Get-KeyAuthorization` like this.

```powershell
$keyauth = Get-KeyAuthorization $auths[0].HTTP01Token
```

Now it's up to you to setup your web server so it responds with the key authorization value when the URL is queried from the Internet. If it's only queryable from your internal LAN, the challenge validation will fail.

!!! note
    If you're using PowerShell functions to create the challenge files, make sure to specify ASCII/ANSI file encoding. Line endings shouldn't matter, but the encoding does in my testing. So if you're using `Out-File`, add `-Encoding ascii`.



## Publishing a DNS Challenge

For a DNS challenge, the ACME server must be able send an TXT record query for a particular record name and receive a key authorization value in the response which is similar to the value it wants for an HTTP challenge. You can build the record name using the following template:

```powershell
$recName = '_acme-challenge.{0}' -f $auths[1].DNSId
```

The key authorization can be generated using `Get-KeyAuthorization` like this. Note the extra `-ForDNS` parameter compared to the HTTP challenge and the reference to `DNS01Token` instead of `HTTP01Token`. Each challenge type within an authorization has a unique token value.

```powershell
$keyauth = Get-KeyAuthorization $auths[1].DNS01Token -ForDNS
```

The astute reader may have realized that in our example, this means the name of the TXT record would be the same for both identifiers, `example.com` and `*.example.com`. They both translate to `_acme-challenge.example.com`. This tends to confuse people at first, but it's really no different than having multiple A records pointing to different IPs for a website. The ACME validation server is smart enough to check all of the returned results and find the one it cares about.

Now it's up to you to publish the record on your DNS server that is queryable from the Internet. Depending on your DNS provider and its replication topology, it may take anywhere from seconds to minutes for the records you create to be queryable from the Internet. Make sure you either know how long it's supposed to take and wait that long before proceeding, or query your authoritative external nameservers directly until they return the expected results.

!!! warning
    In DNS providers that use [anycast](https://www.cloudflare.com/learning/dns/what-is-anycast-dns/) even if you successfully query the nameserver for your record from your location, it may still fail from other locations in the world due to propagation delays. Some providers have an API you can query to know when it is fully propagated. Others don't and you just have to wait longer.

!!! note
    ACME validation servers will also follow CNAME records to validate challenges. This can be useful if your primary DNS server has no API or the security posture of your organization doesn't allow an automated process such as an ACME client to have write access to the zone you need to create TXT records within. If you know this will be the case, you can create a permanent CNAME record for the `_acme-challenge.<FQDN>` name that points to another FQDN somewhere else. Then write your TXT record to that other target and as long as that zone is still Internet-facing, the validation will succeed.


## Publishing a TLS-ALPN Challenge

At the time of this writing, I don't know enough about ALPN to authoritatively write a section on how to use it. But I know it's dependent on the web server software you're using. Here is [Let's Encrypt's documentation](https://letsencrypt.org/docs/challenge-types/#tls-alpn-01) on the subject.


## Notify the ACME Server

Now that you've published all of your key validations for all of your challenges, you're ready to ask the ACME server to check them. The requires the `url` property from the challenge you published which for HTTP/DNS challenges can also be read from `HTTP01Url` or `DNS01Url` on the root authorization object. Use the `Send-ChallengeAck` function like this.

```powershell
# if all of your challenges were published using the same challenge type such as HTTP
$auths.HTTP01Url | Send-ChallengeAck

# if you published challenges of different types, make sure to use the specific URLs associated with them
$auths[0].HTTP01Url | Send-ChallengeAck
$auths[1].DNS01Url | Send-ChallengeAck
```

The challenges are usually validated quickly. But there may be a delay if the ACME server is overloaded. You can poll the status of your authorizations by re-running `Get-PAOrder | Get-PAAuthorization`. Eventually, the status for each one will either be "valid" or "invalid". Good output should look something like this. Notice how the overall status for each challenge is `valid` while the individual challenge status is only valid for the specific challenge types we published.

```
fqdn          status  Expires               DNS01Status HTTP01Status
----          ------  -------               ----------- ------------
example.com   valid   12/24/2020 7:14:33 PM             valid
*.example.com valid   12/24/2020 7:14:33 PM valid
```

# Finishing Up

Now that you have all of your identifiers authorized, your order status should now be "ready" which you can check with `Get-PAOrder -Refresh`. It should look something like this.

```
MainDomain  status  KeyLength SANs            OCSPMustStaple CertExpires Plugin
----------  ------  --------- ----            -------------- ----------- ------
example.com ready   2048      {*.example.com} False                      {Manual}
```

The next step is "finalization" in which you send a the actual x509 certificate request (CSR) to the ACME server. Run the following:

```
Submit-OrderFinalize
```

If you run `Get-PAOrder -Refresh` again, your order status should now be `valid` which means you're ready to download the final signed certificate. Run the following to let Posh-ACME take care of that and build the various combinations of PEM/PFX files.

```
Complete-PAOrder
```

This will also output the final certificate details that should look something like this.

```
Subject         NotAfter             KeyLength Thumbprint                               AllSANs
-------         --------             --------- ----------                               -------
CN=example.com  3/15/2021 4:37:37 PM 2048      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX {example.com, *.example.com}
```

It is also the same output you get from `Get-PACertificate`. Run `Get-PACertificate | fl` to get a full list of cert properties including the filesystem paths where the files are stored.


## Debugging Challenge Failures

If for some reason one or more of your challenge validations failed, you can retrieve the error details from the ACME server like this.

```powershell
(Get-PAOrder | Get-PAAuthorization).challenges.error | fl
```

## Revoking Authorizations

Let's Encrypt and other ACME CAs will generally cache authorizations associated with an account for a period of time. Let's Encrypt caches them for around 30 days which means that if you request another cert in that timeframe with an identifier/name that you've already authorized, the authorization objects won't need to be re-validated. Their status will be immediately valid.

This can be annoying if you're trying to test your challenge validation automation. However, you can revoke your existing authorizations for a given order like this:

```powershell
# NOTE: Without -Force, there will be a confirmation prompt for each name being revoked.
Get-PAorder | Revoke-PAAuthorization -Force
```

This process **does not** revoke the *certificate*. It only revokes the *authorizations* so that you need to re-validate those names when you request a new certificate that contains them.


## Renewals

The concept of a renewal doesn't actually exist in the ACME protocol. What most clients call a renewal is just a new order with the same parameters as last time. So the only thing extra you need to deal with is knowing *when* to renew. When you successfully complete a certificate order, Posh-ACME will attach a `RenewAfter` property to the order object which you can use to calculate whether it's time to renew or not. The property is an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date/time string which can be parsed and checked with [`DateTimeOffset`](https://docs.microsoft.com/en-us/dotnet/api/system.datetimeoffset) like this.

```powershell
$renewAfter = [DateTimeOffset]::Parse((Get-PAOrder).RenewAfter)
if ([DateTimeOffset]::Now -gt $renewAfter) {
    # time to renew
}
```

!!! note
    The RenewAfter value is just a suggestion based on the lifetime of the certificate. Technically, you can renew whenever you want. But if you renew the same certificate too often, you might run into rate limits with your CA.
