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

TODO
