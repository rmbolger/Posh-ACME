# Posh-ACME Tutorial

## Picking a Server

Before we begin, let's configure our ACME server to be the Let's Encrypt *Staging* server. This will let us figure out all of the commands and parameters without likely running into the production server's [rate limits](https://letsencrypt.org/docs/rate-limits/). 

```powershell
Set-PAServer LE_STAGE
```

`LE_STAGE` is a shortcut for the Let's Encrypt Staging server's directory URL. You could do the same thing by specifying the actual URL which is https://acme-staging-v02.api.letsencrypt.org/directory. The other currently supported server shortcut is `LE_PROD` for the Let's Encrypt Production server.

Once you set a server, the module will continue to perform future actions against that server until you change it with another call to `Set-PAServer` or using the `-DirectoryUrl` parameter in a command that supports it. The first time you connect to a server, a link to its Terms of Service will be displayed. You should review it before continuing.

## Your First Certificate

The bare minimum you need to request a certificate is just the domain name.

```powershell
New-PACertificate site1.example.com
```

Since you haven't created an ACME account on this server yet, the command will attempt to create one for you using default settings and you'll get an error about having not agreed to the Terms of Service. Assuming you've reviewed the TOS link from before, add `-AcceptTOS` to the original command to proceed. You only need to do this once when creating a new account. You also probably want to associate an email address with this account so you can receive certificate expiration notifications. So let's do that even though it's not required.

```powershell
New-PACertificate site1.example.com -AcceptTOS -Contact admin@example.com
```

The output of this will have a warning message that you didn't specify a DNS plugin and it's defaulting to the `Manual` plugin. That manual plugin will also be prompting you to create a DNS TXT record to answer the domain's validation challenge.

At this point, you can either `Ctrl-C` to cancel the process and modify your command or go ahead and create the requested TXT record and hit any key to continue. We'll cover DNS plugins next, so for now create the record manually and press a key to continue. If you run into problems creating the TXT record, check out [this wiki page](https://github.com/rmbolger/Posh-ACME/wiki/Notes-about-TXT-record-challenge-validation).

The command will sleep for 2 minutes by default to allow the DNS changes to propagate. Then if the ACME server is able to properly validate the TXT record, the command should finish and give you the folder location of your new certificate. Currently, the responsibility for deploying the certificate to your web server or service is up to you. There may be deployment plugins supported eventually. But for now, the idea is that this module is just a piece of your larger PowerShell based deployment strategy. Among other files, the output folder should contain the following:

- **cert.cer** (Base64 encoded PEM certificate)
- **cert.key** (Base64 encoded PEM private key)
- **cert.pfx** (PKCS12 container with cert+key, importable into Windows cert store with no password)
- **chain.cer** (Base64 encoded PEM with the issuing CA certificate chain)
- **fullchain.cer** (Base64 encoded PEM that is basically cert.cer + chain.cer)

So now you've got a certificate and that's great! But Let's Encrypt certificates expire relatively quickly (3 months). And you won't be able to renew this certificate without going through the manual DNS TXT record hassle again. So let's add a DNS plugin to the process.

## DNS Plugins

The ability to use a DNS plugin is obviously going to depend on your DNS provider and the available plugins in the current release of the module. If your DNS provider is not supported by an existing plugin, please [submit an issue](https://github.com/rmbolger/Posh-ACME/issues) requesting support. If you have PowerShell development skills, you might also try writing a plugin yourself. Instructions can be found in the [DnsPlugins README](/Posh-ACME/DnsPlugins/README.md). Pull requests for new plugins are both welcome and appreciated. It's also possible to redirect ACME DNS validations using a [CNAME record](https://support.dnsimple.com/articles/cname-record/) in your primary zone pointing to another DNS server that is supported. More on that later.

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

The first option requires `[-R53AccessKey] <String>` and `[-R53SecretKey] <SecureString>`. These are API credentials for AWS and presumably as an AWS user, you already know how to generate them. The access key is just a normal string variable. But the secret key is a `SecureString` which takes a bit more effort to setup. So let's create the hashtable we need.

```powershell
$r53Secret = Read-Host Secret -AsSecureString
$r53Params = @{R53AccessKey='ABCD1234'; R53SecretKey=$r53Secret}
```

This `$r53Params` variable is what we'll ultimately pass to the `-PluginArgs` parameter on functions that use it.

Another thing to notice from the plugin's help output is that the description tells us we need to have the `AwsPowershell` module installed. So make sure you have that installed or install it with `Install-Module AwsPowershell` before moving on. I'm hoping most plugins won't need external dependencies like this. But it's good to double check.

Now we know what plugin we're using and we have our plugin arguments in a hashtable. If this is the first time using a particular plugin, it's usually wise to test it before actually trying to use it for a new certificate. So let's do that. The command has no output unless we add the `-Verbose` parameter to show what's going on under the hood.

```powershell
# get a reference to the current account
$acct = Get-PAAccount

Publish-DnsChallenge site1.example.com -Account $acct -Token faketoken -Plugin Route53 -PluginArgs $r53Params -Verbose
```

Assuming there was no error, you should be able to validate that the TXT record was created in the Route53 management console. If so, go ahead and unpublish the record. Otherwise, troubleshoot why it failed and get it working before moving on.

```powershell
Unpublish-DnsChallenge site1.example.com -Account $acct -Token faketoken -Plugin Route53 -PluginArgs $r53Params -Verbose
```
