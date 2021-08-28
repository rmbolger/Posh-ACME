# Tutorial

## Picking a Server

Before we begin, let's configure our ACME server to be the Let's Encrypt *Staging* server. This will let us figure out all of the commands and parameters without likely running into the production server's [rate limits](https://letsencrypt.org/docs/rate-limits/). 

```powershell
Set-PAServer LE_STAGE
```

!!! note
    `LE_STAGE` is a shortcut for the Let's Encrypt Staging server's directory URL. You could do the same thing by specifying the actual URL which is `https://acme-staging-v02.api.letsencrypt.org/directory` and this module should work with any ACME compliant directory URL. Other currently supported shortcuts include `LE_PROD`, `BUYPASS_PROD`, `BUYPASS_TEST`, and `ZEROSSL_PROD`.

Once you set a server, the module will continue to perform future actions against that server until you change it with another call to `Set-PAServer`. The first time you connect to a server, a link to its Terms of Service will be displayed. You should review it before continuing.

## Your First Certificate

The bare minimum you need to request a certificate is just the domain name.

```powershell
New-PACertificate example.com
```

Since you haven't created an ACME account on this server yet, the command will attempt to create one for you using default settings and you'll get an error about having not agreed to the Terms of Service. Assuming you've reviewed the TOS link from before, add `-AcceptTOS` to the original command to proceed. You only need to do this once when creating a new account. You also probably want to associate an email address with this account so you can receive certificate expiration notifications. So let's do that even though it's not required.

```powershell
New-PACertificate example.com -AcceptTOS -Contact 'admin@example.com'
```

!!! note
    Multiple email addresses per account are supported. Just pass it an array of addresses.

Because you didn't specify a plugin, it will default to using the `Manual` DNS plugin. That manual plugin will also be prompting you to create a DNS TXT record to answer the ACME server's validation challenge for the domain.

At this point, you can either press `Ctrl+C` to cancel the process and modify your command or go ahead and create the requested TXT record and hit any key to continue. We'll cover plugins next, so for now create the record manually and press a key to continue. If you run into problems creating the TXT record, check out [Troubleshooting DNS Validation](Guides/Troubleshooting-DNS-Validation.md).

The command will sleep for 2 minutes by default to allow the DNS changes to propagate. Then if the ACME server is able to properly validate the TXT record, the final certificate files are generated and the command should output the details of your new certificate. Only a subset of the details are displayed by default. To see them all, run `Get-PACertificate | fl`. The files generated in the output folder should contain the following:

- **cert.cer** (Base64 encoded PEM certificate)
- **cert.key** (Base64 encoded PEM private key)
- **cert.pfx** (PKCS12 container with cert+key)
- **chain.cer** (Base64 encoded PEM with the issuing CA chain)
- **chainX.cer** (Base64 encoded PEM with alternate issuing CA chains)
- **fullchain.cer** (Base64 encoded PEM with cert+chain)
- **fullchain.pfx** (PKCS12 container with cert+key+chain)

Posh-ACME is only designed to *obtain* certificates, not deploy them to your web server or service. The certificate details are written to the pipeline so you can either save them to a variable or pipe the output to another command. [Posh-ACME.Deploy](https://github.com/rmbolger/Posh-ACME.Deploy) is a sister module containing some example deployment functions for common services to get you started. But ultimately, it's up to you how you want to deploy your certificates.

The password on the PFX files is `poshacme` because we didn't override the default with `-PfxPass` or `-PfxPassSecure`. If you're running PowerShell with elevated privileges on Windows, you can also add the `-Install` switch to automatically import the certificate into the local computer's certificate store.

So now you have a certificate and that's great! But Let's Encrypt certificates expire relatively quickly (90 days). And you won't be able to renew this certificate without going through the manual DNS TXT record hassle again. So let's add a validation plugin to the process.

## Plugins

The ACME protocol currently supports three types of challenges to prove you control the domain you're requesting a certificate for: `dns-01`, `http-01`, and `tls-alpn-01`. We are going to focus on `dns-01` because it is the only one that can be used to request wildcard (*.example.com) certificates and the majority of Posh-ACME plugins are for [DNS providers](Plugins/index.md#dns-plugins).

The ability to use a DNS plugin is going to depend on whether your DNS provider has a supported plugin in the current version of the module. If not, please [submit an issue](https://github.com/rmbolger/Posh-ACME/issues) requesting support. If you have PowerShell development skills, you might also try writing a plugin yourself. Instructions can be found in the [Plugins README](https://github.com/rmbolger/Posh-ACME/blob/main/Posh-ACME/Plugins/README.md). Pull requests for new plugins are both welcome and appreciated. It's also possible to redirect ACME DNS validations using a [CNAME record](https://support.dnsimple.com/articles/cname-record/) in your primary zone pointing to another DNS server that is supported. More on that later.

The first thing to do is figure out which DNS plugin to use and how to use it. Start by listing the available plugins.

```powershell
Get-PAPlugin
```

Most plugins have a detailed usage guide in the project wiki. In these examples, we'll use the AWS Route53 plugin. Here's a quick shortcut to get to the usage guide. This will open the default browser to the page on Windows and just display the URL on non-Windows.

```powershell
Get-PAPlugin Route53 -Guide
```

Using a plugin will almost always require creating a hashtable with required plugin parameters. To see a quick reference of the available parameter sets try this:

```ps1con
PS> Get-PAPlugin Route53 -Params

    Set Name: Keys (Default)

Parameter    Type         IsMandatory
---------    ----         -----------
R53AccessKey String       True
R53SecretKey SecureString True

    Set Name: KeysInsecure

Parameter            Type   IsMandatory
---------            ----   -----------
R53AccessKey         String True
R53SecretKeyInsecure String True

    Set Name: Profile

Parameter      Type   IsMandatory
---------      ----   -----------
R53ProfileName String True

    Set Name: IAMRole

Parameter     Type            IsMandatory
---------     ----            -----------
R53UseIAMRole SwitchParameter True
```

We can see there are four different parameter sets we can use: `Keys`, `KeysInsecure`, `Profile`, and `IAMRole`. The `Keys` set requires `R53AccessKey` and `R53SecretKey`. These are API credentials for AWS and presumably as an AWS user, you already know how to generate them. The access key is just a normal String variable. But the secret key is a `SecureString` which takes a bit more effort to setup. So let's create the hashtable we need.

```powershell
$r53Secret = Read-Host 'Enter Secret' -AsSecureString
$pArgs = @{R53AccessKey='ABCD1234'; R53SecretKey=$r53Secret}
```

This `$pArgs` variable is what we'll pass to the `-PluginArgs` parameter on functions that use it.

Now we know what plugin we're using and we have our plugin arguments in a hashtable. If this is the first time using a particular plugin, it's usually wise to test it before actually trying to use it for a new certificate. So let's do that. The command has no output unless we add the `-Verbose` switch to show what's going on under the hood.

```powershell
# get a reference to the current account
$acct = Get-PAAccount

Publish-Challenge example.com -Account $acct -Token faketoken -Plugin Route53 -PluginArgs $pArgs -Verbose
```

Assuming there was no error, you should be able to validate that the TXT record was created in the Route53 management console. If so, go ahead and unpublish the record. Otherwise, troubleshoot why it failed and get it working before moving on.

```powershell
Unpublish-Challenge example.com -Account $acct -Token faketoken -Plugin Route53 -PluginArgs $pArgs -Verbose
```

All we have left to do is add the necessary plugin parameters to our original certificate request command. But let's get crazy and change it up a bit by making the cert a wildcard cert with the root domain as a [subject alternative name (SAN)](https://en.wikipedia.org/wiki/Subject_Alternative_Name).

```powershell
New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact 'admin@example.com' -Plugin Route53 `
    -PluginArgs $pArgs -Verbose
```

!!! warning
    According to current Let's Encrypt [rate limits](https://letsencrypt.org/docs/rate-limits/), a single certificate can have up to 100 names. The only caveat is that wildcard certs may not contain any SANs that would overlap with the wildcard entry. So you'll get an error if you try to put `*.example.com` and `www.example.com` in the same cert. But `*.example.com` and `example.com` or `www.sub.example.com` are just fine.

We included the `-Verbose` switch again so we can see what's going on. But normally, that wouldn't be necessary. Assuming everything went well, you should now have a fresh new wildcard cert that required no user interaction. Keep in mind, HTTP plugins work the exactly the same way as DNS plugins. They just can't be used to validate wildcard names in certs from Let's Encrypt.

## Renewals and Deployment

Now that you have a cert order that can successfully answer DNS challenges via a plugin, it's even easier to renew it.

```powershell
Submit-Renewal
```

!!! note
    Be aware that renewals don’t count against your Certificates per Registered Domain limit, but they are subject to a Duplicate Certificate limit of 5 per week.

The module saves all of the parameters associated with an order and re-uses the same values to renew it. It will throw a warning right now because the cert hasn't reached the suggested renewal window. But you can use `-Force` to do it anyway if you want to try it. Let's Encrypt currently caches authorizations for roughly 30 days, so the forced renewal won't need to go through validating the challenges again. But you can de-authorize your existing challenges using the following command if you want to test the validation process again.

```powershell
Get-PAOrder | Revoke-PAAuthorization
```

If you have multiple orders on an account or even multiple accounts, there are flags to renew all of those as well.

```powershell
# renew all orders on the current account
Submit-Renewal -AllOrders

# renew all orders across all accounts in the current profile
Submit-Renewal -AllAccounts
```

!!! note
    The `-Force` parameter works with these as well.

### Task Scheduler / Cron

Because PowerShell has no native way to run recurring tasks, you'll need to set something up using whatever job scheduling utility your OS provides like Task Scheduler on Windows or cron on Linux. It is suggested to run the job once or twice a day at ideally randomized times. At the very least, try not to run them directly on any hour marks to avoid potential load spikes on the ACME server. Generally, **the task must run as the same user you're currently logged in as** because the Posh-ACME config is stored in your local user profile. However, it's possible to [change the default config location](Guides/Using-an-Alternate-Config-Location.md).

As mentioned earlier, Posh-ACME doesn't handle certificate deployment. So you'll likely want to create a script to both renew the cert and deploy it to your service/application. All the details you should need to deploy the cert are in the PACertificate object that is returned by `Submit-Renewal`. It's also the same object returned by `New-PACertificate` and `Get-PACertificate`; the latter being useful to test deployment scripts with.

`Submit-Renewal` will only return PACertificate objects for certs that were actually renewed successfully. So the typical template for a renew/deploy script might look something like this.

```powershell
Set-PAOrder example.com
if ($cert = Submit-Renewal) {
    # do stuff with $cert to deploy it
}
```

For a job that is renewing multiple certificates, it might look more like this.

```powershell
Submit-Renewal -AllOrders | ForEach-Object {
    $cert = $_
    if ($cert.MainDomain -eq 'example.com') {
        # deploy for example.com
    } elseif ($cert.MainDomain -eq 'example.net') {
        # deploy for example.com
    } else {
        # deploy for everything else
    }
}
```

### Updating Plugin Parameters on Renewal

Credentials and Tokens can change over time and some plugins can be used with purposefully short-lived access tokens. In these cases, you can specify the new plugin parameters using the `-PluginArgs` parameter on either `Set-PAOrder` or `Submit-Renewal`. **The full set of plugin arguments must be specified.**

As an example, consider the case for the Azure DNS plugin:

```powershell
# renew specifying new plugin arguments
Submit-Renewal -PluginArgs @{AZSubscriptionId='mysubscriptionid';AZAccessToken='myaccesstoken'}
```

## Going Into Production

Now that you've got everything working against the Let's Encrypt staging server, all you have to do is switch over to the production server and re-run your `New-PACertificate` command to get your shiny new publicly trusted certificate.

```powershell
Set-PAServer LE_PROD

New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact 'admin@example.com' `
    -Plugin Route53 -PluginArgs $pArgs -Verbose
```
