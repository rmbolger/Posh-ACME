# Posh-ACME Tutorial

- [Picking a Server](#picking-a-server)
- [Your First Certificate](#your-first-certificate)
- [DNS Plugins](#dns-plugins)
- [Renewing A Certificate](#renewing-a-certificate)
- [Going Into Production](#going-into-production)
- [(Advanced) DNS Challenge Aliases](#advanced-dns-challenge-aliases)

## Picking a Server

Before we begin, let's configure our ACME server to be the Let's Encrypt *Staging* server. This will let us figure out all of the commands and parameters without likely running into the production server's [rate limits](https://letsencrypt.org/docs/rate-limits/). 

```powershell
Set-PAServer LE_STAGE
```

`LE_STAGE` is a shortcut for the Let's Encrypt Staging server's directory URL. You could do the same thing by specifying the actual URL which is https://acme-staging-v02.api.letsencrypt.org/directory. The other currently supported server shortcut is `LE_PROD` for the Let's Encrypt Production server. Any ACMEv2 compliant directory URL will work though.

Once you set a server, the module will continue to perform future actions against that server until you change it with another call to `Set-PAServer`. The first time you connect to a server, a link to its Terms of Service will be displayed. You should review it before continuing.

## Your First Certificate

The bare minimum you need to request a certificate is just the domain name.

```powershell
New-PACertificate site1.example.com
```

Since you haven't created an ACME account on this server yet, the command will attempt to create one for you using default settings and you'll get an error about having not agreed to the Terms of Service. Assuming you've reviewed the TOS link from before, add `-AcceptTOS` to the original command to proceed. You only need to do this once when creating a new account. You also probably want to associate an email address with this account so you can receive certificate expiration notifications. So let's do that even though it's not required. *Note: Multiple email addresses per account are supported. Just pass it an array of addresses.*

```powershell
New-PACertificate site1.example.com -AcceptTOS -Contact admin@example.com
```

The output of this will have a warning message that you didn't specify a DNS plugin and it's defaulting to the `Manual` plugin. That manual plugin will also be prompting you to create a DNS TXT record to answer the domain's validation challenge.

At this point, you can either `Ctrl-C` to cancel the process and modify your command or go ahead and create the requested TXT record and hit any key to continue. We'll cover DNS plugins next, so for now create the record manually and press a key to continue. If you run into problems creating the TXT record, check out the [Troubleshooting DNS Challenge Validation](https://github.com/rmbolger/Posh-ACME/wiki/Troubleshooting-DNS-Challenge-Validation) wiki page.

The command will sleep for 2 minutes by default to allow the DNS changes to propagate. Then if the ACME server is able to properly validate the TXT record, the final certificate files are generated and the command should output the details of your new certificate. Only a subset of the details are displayed by default. To see them all, run `Get-PACertificate | fl`. The files generated in the output folder should contain the following:

- **cert.cer** (Base64 encoded PEM certificate)
- **cert.key** (Base64 encoded PEM private key)
- **cert.pfx** (PKCS12 container with cert+key)
- **chain.cer** (Base64 encoded PEM with the issuing CA certificate chain)
- **fullchain.cer** (Base64 encoded PEM with cert+chain)
- **fullchain.pfx** (PKCS12 container with cert+key+chain)

Currently, the responsibility for deploying the certificate to your web server or service is up to you. There may be deployment plugins supported eventually. But for now, the idea is that this module is just a piece of your larger PowerShell based deployment strategy. The certificate details are written to the pipeline so you can either save them to a variable or pipe the output to another command.
The password set for the PFX files is `poshacme` because we didn't override the default with `-PfxPass`. If you're running PowerShell with elevated privileges on Windows, you can also add the `-Install` switch to automatically import the certificate into the local computer's certificate store.

So now you've got a certificate and that's great! But Let's Encrypt certificates expire relatively quickly (90 days). And you won't be able to renew this certificate without going through the manual DNS TXT record hassle again. So let's add a DNS plugin to the process.

## DNS Plugins

The ability to use a DNS plugin is going to depend on your DNS provider and the [available plugins](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) in the current version of the module. If your DNS provider is not supported by an existing plugin, please [submit an issue](https://github.com/rmbolger/Posh-ACME/issues) requesting support. If you have PowerShell development skills, you might also try writing a plugin yourself. Instructions can be found in the [DnsPlugins README](/Posh-ACME/DnsPlugins/README.md). Pull requests for new plugins are both welcome and appreciated. It's also possible to redirect ACME DNS validations using a [CNAME record](https://support.dnsimple.com/articles/cname-record/) in your primary zone pointing to another DNS server that is supported. More on that later.

The first thing to do is figure out which DNS plugin to use and how to use it. Start by listing the available plugins.

```powershell
Get-DnsPlugins
```

Using a DNS plugin will almost always require creating a hashtable with required plugin parameters. After choosing a plugin, find out what parameters are required by displaying the help for that plugin. In these examples, we'll use the AWS Route53 plugin.

```powershell
Get-DnsPluginHelp Route53 Add
```

This forwards a help request to the plugin's Add function. The output will look something like this. *Note: You can't actually use the `get-help` calls in the Remarks section because the function isn't actually exposed by the module. But most of the parameters you could use with `Get-Help` can also be used with `Get-DnsPluginHelp`*

```
NAME
    Add-DnsTxtRoute53

SYNOPSIS
    Add a DNS TXT record to a Route53 hosted zone.


SYNTAX
    Add-DnsTxtRoute53 [-RecordName] <String> [-TxtValue] <String> [-R53AccessKey] <String> [-R53SecretKey]
    <SecureString> [-ExtraParams <Object>] [<CommonParameters>]

    Add-DnsTxtRoute53 [-RecordName] <String> [-TxtValue] <String> -R53ProfileName <String> [-ExtraParams <Object>]
    [<CommonParameters>]


DESCRIPTION
    This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either
    specify an Access/Secret key pair or the name of an AWS credential profile previously stored using
    Set-AWSCredential.


RELATED LINKS

REMARKS
    To see the examples, type: "get-help Add-DnsTxtRoute53 -examples".
    For more information, type: "get-help Add-DnsTxtRoute53 -detailed".
    For technical information, type: "get-help Add-DnsTxtRoute53 -full".
```

From the `SYNTAX` section, we can see there are two different ways to call the function. Regardless of the plugin, you can always ignore `RecordName`, `TxtValue`, and `ExtraParams` as those are handled by the module. 

The first option requires `[-R53AccessKey] <String>` and `[-R53SecretKey] <SecureString>`. These are API credentials for AWS and presumably as an AWS user, you already know how to generate them. If not, most plugins should have an associated usage guide called `<Plugin>-Readme.md` that can provide more in-depth help. The access key is just a normal string variable. But the secret key is a `SecureString` which takes a bit more effort to setup. So let's create the hashtable we need.

```powershell
$r53Secret = Read-Host Secret -AsSecureString
$r53Params = @{R53AccessKey='ABCD1234'; R53SecretKey=$r53Secret}
```

This `$r53Params` variable is what we'll pass to the `-PluginArgs` parameter on functions that use it.

Most plugins also have a Usage Guide that can provide more detailed help using or setting up the plugin. They're all linked from the [List of Supported DNS Providers](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) wiki page, but you can also read them locally from the DnsPlugins folder in the module. They're Markdown formatted and called `<plugin>-Readme.md`.

Now we know what plugin we're using and we have our plugin arguments in a hashtable. If this is the first time using a particular plugin, it's usually wise to test it before actually trying to use it for a new certificate. So let's do that. The command has no output unless we add the `-Verbose` switch to show what's going on under the hood.

```powershell
# get a reference to the current account
$acct = Get-PAAccount

Publish-DnsChallenge site1.example.com -Account $acct -Token faketoken -Plugin Route53 `
    -PluginArgs $r53Params -Verbose
```

Assuming there was no error, you should be able to validate that the TXT record was created in the Route53 management console. If so, go ahead and unpublish the record. Otherwise, troubleshoot why it failed and get it working before moving on.

```powershell
Unpublish-DnsChallenge site1.example.com -Account $acct -Token faketoken -Plugin Route53 `
    -PluginArgs $r53Params -Verbose
```

All we have left to do is add the necessary plugin parameters to our original certificate request command. But let's get crazy and change it up a bit by making the cert a wildcard cert with the root domain as a subject alternative name (SAN).

*Note: According to current Let's Encrypt [rate limits](https://letsencrypt.org/docs/rate-limits/), a single certificate can have up to 100 names. The only caveat is that wildcard certs may not contain any SANs that would overlap with the wildcard entry. So you'll get an error if you try to put `*.example.com` and `site1.example.com` in the same cert. But `*.example.com` and `example.com` or `site1.sub1.example.com` are just fine.*

```powershell
New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact admin@example.com -DnsPlugin Route53 `
    -PluginArgs $r53Params -Verbose
```

We included the `-Verbose` switch again so we can see what's going on. But normally, that wouldn't be necessary. Assuming everything went well, you should now have a fresh new wildcard cert that required no user interaction.

Keep in mind that **PluginArgs are saved to the local profile and tied to the current ACME account**. This is what enables easy renewals that we'll discuss in the next section. It also means you can generate additional certificates without having to specify the PluginArgs parameter again as long as you're using the same DNS plugin. However, because new values overwrite old values, it means that you can't use different sets of parameters for different certificates unless you create a different ACME account.

## Renewing A Certificate

Now that you have a cert that can successfully answer DNS challenges via a plugin, it's even easier to renew it.

```powershell
Submit-Renewal
```

The module saves all of the parameters associated with an order and re-uses the same values to renew it. It will throw a warning right now because the cert hasn't reached the suggested renewal window. But you can use `-Force` to do it anyway if you want to try it. If you end up with multiple certs or even multiple accounts with multiple certs, there are flags to renew all of those as well.

```powershell
# renew all orders on the current account
Submit-Renewal -AllOrders

# renew all orders across all accounts in the current profile
Submit-Renewal -AllAccounts
```

These are designed to be used in a daily scheduled task. **Make sure to have it run as the same user you're currently logged in as** because the module config is all stored in your local profile. Each day, it will check the existing certs for ones that have reached the renewal window and renew them. It will just ignore the ones that aren't ready yet.

### Updating DNS Plugin Parameters on Renewal

DNS provider credentials can change over time and some plugins can be used with purposefully short-lived access tokens. In these cases, you can specify the new plugin parameters using the ```-PluginArgs``` parameter. **The full set of plugin arguments must be specified.**

As an example, consider the case for the Azure DNS plugin:

```powershell
# renew specifying new plugin arguments
Submit-Renewal -PluginArgs @{AZSubscriptionId='mysubscriptionid',AZAccessToken='myaccesstoken'}
```

## Going Into Production

Now that you've got everything working against the Let's Encrypt staging server, all you have to do is switch over to the production server and re-run your `New-PACertificate` command to get your shiny new publicly trusted certificate.

```powershell
Set-PAServer LE_PROD

New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact admin@example.com -DnsPlugin Route53 `
    -PluginArgs $r53Params -Verbose
```

## (Advanced) DNS Challenge Aliases

### Background

There are two relatively common issues that come up when people try to automate ACME certs using DNS challenges. The first is that the DNS provider hosting the zone either doesn't have an API or the ACME client doesn't have a plugin to support it. The second is that for security reasons, the business may not want to save API credentials for their critical DNS zone on an internet-facing web server.

The workaround for both of these involves using a [CNAME record](https://support.dnsimple.com/articles/cname-record/) to redirect challenge requests to another DNS zone. When the ACME server goes to validate the challenges, it will follow the CNAME and check the challenge token from the redirected record. If the original problem was no API or no plugin, you'd put the redirected zone on a provider with an API and a supported plugin. If the original problem was security related, you'd make the redirected zone a less important one. The downside is the extra manual step required to add the CNAME for each new cert or name in a cert. But you only have to do that once ever for each name.

### Creating CNAMEs

So how do we do that? First, you have to understand how the ACME protocol chooses what record to query for each name in a certificate. Non-wildcard names have `_acme-challenge.` prepended to them. Wildcard names use the same prefix but it replaces the `*.` prefix. So for example:

Cert Name | Challenge Record
--- | ---
example.com | _acme-challenge.example.com
*.example.com | _acme-challenge.example.com
sub1.example.com | _acme-challenge.sub1.example.com
*.sub1.example.com | _acme-challenge.sub1.example.com
site1.sub1.sub2.example.com | _acme-challenge.site1.sub1.sub2.example.com

You may have noticed that a wildcard name and a non-wildcard for the same root domain have the same challenge record. That's not a mistake and the ACME server does actually expect to get two different values for the same TXT record. What it means for you though is that you only have one CNAME to create for both types of names.

Where do you point the CNAMEs to? It doesn't really matter as long as the ACME server can query it from the Internet and Posh-ACME can create the necessary records there. Some people choose to use the same `_acme-challenge.` prefix for clarity. Some people use a different prefix because their provider doesn't allow names to start with a `_` character. Some people just point all of their CNAMEs to the exact same place. **Just don't point the CNAME at the apex of a domain.** Examples:

Challenge Record | CNAME Target
--- | ---
_acme-challenge.example.com | _acme-challenge.example.net
_acme-challenge.example.com | acme.example.net
_acme-challenge.example.com | _acme-challenge.validation.example.net
_acme-challenge.example.com<br>_acme-challenge.sub1.example.com<br>_acme-challenge.sub2.example.com | acme.example.net
_acme-challenge.example.com | **(BAD)** example.net

**Important:** Don't point too many CNAMES at the same record. Let's Encrypt's ACME implementation can only deal with DNS responses [up to 4096 bytes](https://github.com/letsencrypt/boulder/pull/3467) which is roughly 60-70 TXT records depending on your DNS server and query parameters. If your record is too big, the validations will fail.

### Testing

You should verify your CNAME got created correctly before you try and use it. If you're inside a business with a split-brain DNS infrastructure, you might need to explicitly query a public external resolver like CloudFlare's 1.1.1.1. However, some modern firewalls can be configured to prevent this ability. So make sure you can successfully query a known-good external record first.

```
C:\>nslookup -q=CNAME _acme-challenge.example.com 1.1.1.1
Server:  1dot1dot1dot1.cloudflare-dns.com
Address:  1.1.1.1

Non-authoritative answer:
_acme-challenge.example.com  canonical name = acme.example.net
```

### Using the Challenge Alias

Now that your CNAMEs are all setup, you just have to add one more parameter to your certificate request command, `-DnsAlias`. It works just like `-DnsPlugin` as an array that should have one element for each domain in the request. But if all of your CNAMEs point to the same place, you can just specify the alias once and it will use that alias for all the names.

```powershell
New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact admin@example.com -DnsPlugin Route53 `
    -PluginArgs $r53Params -DnsAlias acme.example.net -Verbose
```
