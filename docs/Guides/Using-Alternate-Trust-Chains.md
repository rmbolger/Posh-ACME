# Using Alternate Trust Chains

The ACME protocol allows for a CA to offer alternate trust chains in order to accommodate the natural lifecycle of Root and Issuing certificates. As of this writing, the only public ACME CA that currently offers alternate trust chains is Let's Encrypt. But the instructions in this guide should work for any ACME CA.

## Let's Encrypt Options

To understand why Let's Encrypt is offering multiple trust chains and why you as a site/service operator would choose one or the other, it is helpful to read the following posts:

- [DST Root CA X3 Expiration (September 2021)](https://letsencrypt.org/docs/dst-root-ca-x3-expiration-september-2021/)
- [Extending Android Device Compatibility for Let's Encrypt Certificates](https://letsencrypt.org/2020/12/21/extending-android-compatibility.html)
- [Production Chain Changes](https://community.letsencrypt.org/t/production-chain-changes/150739)

Your default choice is currently the longer chain that builds to the expiring `DST Root CA X3` 3rd party certificate which should be compatible with almost all Android devices until 2024. The alternate choice is the shorter chain that builds to the `ISRG Root X1` self-signed certificate which doesn't expire until 2035.

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
    Changing the chain on an existing certificate will only update the files in the Posh-ACME order folder. Even if the order has the `Install` property set to `$true`, it will not re-import the current certificate to the Windows certificate store. It will only do that on the next renewal.

## Serving the Alternate Chain from Windows

While the `-PreferredChain` option will make Posh-ACME download the alternate chain for the files in your config, you may notice that on Windows your website/application is still serving the default chain. Unlike many Linux applications that have explicit configuration options for chain configuration, applications that use the Windows certificate store usually rely on the underlying operating system to decide what chain to serve with the leaf certificate.

There does not seem to be a way to differentiate the chains being served based on application. All websites and applications using leaf certs from the same Intermediate CA will serve the same chain. But it is possible to influence which chain based on the contents of the `Intermediate Certification Authorities` cert store.

Both chains start with the same [R3 intermediate](https://letsencrypt.org/certs/lets-encrypt-r3.der) cert (Thumbprint: a053375bfe84e8b748782c7cee15827a6af5a405) signed by `ISRG Root X1` and should be added to your Intermediate cert store if it's not already there. If you wish to serve the short chain, this is all you need assuming the [self-signed ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.der) is in your Trusted Root store as well.

If you want to serve the longer chain, you will also need to add the [cross-signed ISRG Root X1](https://letsencrypt.org/certs/isrg-root-x2-cross-signed.der) cert (Thumbprint: 933c6ddee95c9c41a40f9f50493d82be03ad87bf) to the Intermediate cert store. Windows will find this cross-signed cert before it finds the self-signed copy in Trusted Roots and add it to the chain being served by the applications.

!!! note
    These suggestions are based on the observed behavior of Windows Server 2019 and 2022 prior to the expiration of `DST Root CA X3`. This document will be updated if the behavior changes following that expiration.

The changes require a reboot to take effect.
