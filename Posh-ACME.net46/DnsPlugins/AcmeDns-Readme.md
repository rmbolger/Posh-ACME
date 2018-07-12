# How To Use the AcmeDns Plugin

This plugin works against [acme-dns](https://github.com/joohoi/acme-dns) which is limited DNS server implementation designed specifically to handle DNS challenges for the ACME protocol. It is useful when your actual DNS provider doesn't have a supported plugin or security policies/limitations in your environment don't allow you to use a supported plugin. Initial certificate generation requires some manual steps, but renewals can be automated just like other plugins.

## Setup

While there is a publicly accessible acme-dns instance that you can use to test with at https://auth.acme-dns.io, it is not recommended for production use. Instead, you should run your own instance using the [install instructions](https://github.com/joohoi/acme-dns#installation) on the project page.

Once you have your instance running, it needs to be accessible via HTTPS to your client and via standard DNS (port 53) to ACME servers on the Internet. Then, all you need is its hostname to use the plugin.

## Using the Plugin

The only required parameter for the plugin is `ACMEServer` which is the hostname of the acme-dns instance you are using. There is also an optional `ACMEAllowFrom` parameter which takes an array of strings with networks specified in CIDR notation. If included, these networks will be the only ones that can send TXT record updates to the server for the registrations that get created as part of the certificate request. In some environments, it may make more sense to control network access via standard firewalls.

This plugin is ultimately using CNAME aliases for DNS challenges under the hood. The first time you use it, you will be prompted to create the necessary CNAME records for each new name included in a cert.

```
PS C:\> New-PACertificate example.com -DnsPlugin AcmeDns -PluginArgs @{ACMEServer='auth.acme-dns.io'}

Please create the following CNAME records:
------------------------------------------
_acme-challenge.example.com -> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.auth.acme-dns.io
------------------------------------------

Press any key to continue.:
```

For each CNAME in the list, you need to create the associated record on your DNS server before continuing. Assuming the records get created properly, the process should complete succesfully. Future renewals will complete without additional prompting as long as no new names are added to the cert.

## (Advanced) Pre-registration and CNAME creation

Some organizations may want to pre-create the acme-dns registrations and add the necessary CNAME records to their DNS infrastructure prior to working with Posh-ACME. In this case, you can avoid the first-run interactive prompts by passing the necessary registration object(s) in a hashtable using the `ACMERegistration` parameter.

For example, a cert that contains `example.com` and `www.example.com` will have two acme-dns registrations created (one for each name). Each registration contains four values: subdomain, username, password, and full domain. Creating the registration objects and creating the certificate might look something like this:

```powershell
$reg = @{
    '_acme-challenge.example.com' = @(
        # the array order of these values is important
        '9aa5ce59-635e-440c-b2ca-12ee3503ddee'                        # subdomain
        '1b5cce3b-255d-4ffb-a81f-a9e27167ac7a'                        # username
        'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'                         # password
        '9aa5ce59-635e-440c-b2ca-12ee3503ddee.acmedns.example.com'    # full domain
    )
    '_acme-challenge.www.example.com' = @(
        'ec6ec1f4-836e-462e-b577-b2f4e04d7291'
        'aeb00c77-852b-465e-9b27-984bc6cb12f5'
        'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
        'ec6ec1f4-836e-462e-b577-b2f4e04d7291.acmedns.example.com'
    )
}

$pArgs = @{
    ACMEServer = 'acmedns.example.com'
    ACMERegistration = $reg
}

New-PACertificate example.com,www.example.com -DnsPlugin AcmeDns -PluginArgs $pArgs
```
