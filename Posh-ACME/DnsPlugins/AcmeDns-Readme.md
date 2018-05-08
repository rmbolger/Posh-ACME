# How To Use the AcmeDns Plugin

This plugin works against [acme-dns](https://github.com/joohoi/acme-dns) which is limited DNS server implementation designed specifically to handle ACME DNS challenges. It is useful when your actual DNS provider doesn't have a supported plugin or security policies/limitations in your environment don't allow you to use a supported plugin. Initial certificate generation requires some manual steps, but renewals can be automated just like other plugins.

## Setup

While there is a publicly accessible acme-dns instance that you can use to test with at https://auth.acme-dns.io, it is not recommended for production use. Instead, you should run your own instance using the [install instructions](https://github.com/joohoi/acme-dns#installation) on the project page.

Once you have your instance running, it needs to be accessible via HTTPS to your client and via standard DNS (port 53) to ACME servers on the Internet. Then, all you need is its hostname to use the plugin.

## Using the Plugin

The only required parameter for the plugin is `ACMEServer` which is the hostname of the acme-dns instance you are using. There is also an optional `ACMEAllowFrom` parameter which takes an array of strings with networks specified in CIDR notation. If included, these networks will be the only ones that can send TXT record updates to the server for the registrations that get created as part of the certificate request. In some environments, it may make more sense to control network access via standard firewalls.

Because this plugin is ultimately using CNAME aliases for DNS challenges under the hood. When you use it, you will be prompted to create the necessary CNAME records for each new name included in a cert.

```
PS C:\> New-PACertificate test.example.com -DnsPlugin AcmeDns -PluginArgs @{ACMEServer='auth.acme-dns.io'}

Please create the following CNAME records:
------------------------------------------
_acme-challenge.test.example.com -> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.auth.acme-dns.io
------------------------------------------

Press any key to continue.:
```

For each CNAME in the list, you need to create the associated record in your DNS server before continuing. Assuming the records get created successfully, the process should complete as normal. Subsequent renewals will complete without additional prompting.
