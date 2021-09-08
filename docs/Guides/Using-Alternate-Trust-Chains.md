# Using Alternate Trust Chains

The ACME protocol allows for a CA to offer alternate trust chains in order to accommodate the natural lifecycle of Root and Issuing certificates. As of this writing, the only public ACME CA that currently offers alternate trust chains is Let's Encrypt. But the instructions in this guide should work for any ACME CA.

## Let's Encrypt Options

To understand why Let's Encrypt is offering multiple trust chains and why you as a site/service operator would choose one or the other, it is helpful to read the following posts:

- [DST Root CA X3 Expiration (September 2021)](https://letsencrypt.org/docs/dst-root-ca-x3-expiration-september-2021/)
- [Extending Android Device Compatibility for Let's Encrypt Certificates](https://letsencrypt.org/2020/12/21/extending-android-compatibility.html)
- [Production Chain Changes](https://community.letsencrypt.org/t/production-chain-changes/150739)

Your default choice is currently the longer chain that builds to the expiring `DST Root CA X3` 3rd party certificate which should be compatible with almost all Android devices until 2024. The alternate choice is the shorter chain that builds to the non-expiring `ISRG Root X1` self-signed certificate.

Ultimately, your choice should depend on the clients that are connecting to your service. But if you don't know, it's probably safest to just leave the default. Let's Encrypt also has a [Certificate Compatibility](https://letsencrypt.org/docs/certificate-compatibility/) page that can help.

It is also a perfectly valid option to switch to a different [public ACME CA](ACME-CA-Comparison.md) either permanently or until the dust settles on the DST Root expiration.

## Picking an Alternate Chain

`New-PACertificate`, `New-PAOrder`, and `Set-PAOrder` all have a `-PreferredChain` parameter that work the same way. You provide the common name of a certificate in the chain you want to select. For Let's Encrypt, that would be `ISRG Root X1` even though it exists in both chains. The alternate chain wins because that cert is closer to the root (it *is* the root) than the default chain.

Here's an example of getting a new cert with the alternate chain using [splatting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting).

```powershell
$certParams = @{
    Domain = '*.example.com','example.com'
    AcceptTOS = $true
    Contact = 'admin@example.com'
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    PreferredChain = 'ISRG Root X1'
}
New-PACertificate @certParams
```

You can also modify an existing order to use the alternate chain which will change both the current certificate files (if they exist) and future renewals.

```powershell
Set-PAOrder -Name 'example.com' -PreferredChain 'ISRG Root X1'
```

!!! warning
    Changing the chain on an existing certificate will only update the files in the Posh-ACME order folder. Even if the order has the `Install` property set to `$true`, it will not re-import the current certificate to the Windows certificate store even. It will only do that on the next renewal.
