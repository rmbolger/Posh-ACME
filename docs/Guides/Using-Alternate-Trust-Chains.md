# Using Alternate Trust Chains

The ACME protocol allows for a CA to offer alternate trust chains in order to accommodate the natural lifecycle of Root and Issuing certificates. As of this writing, the only public ACME CA that currently offers alternate trust chains is Let's Encrypt. But the instructions in this guide should work for any ACME CA.

## Let's Encrypt Options

To understand why Let's Encrypt is offering multiple trust chains and why you as a site/service operator would choose one or the other, it is helpful to read the following posts:

- [DST Root CA X3 Expiration (September 2021)](https://letsencrypt.org/docs/dst-root-ca-x3-expiration-september-2021/)
- [Extending Android Device Compatibility for Let's Encrypt Certificates](https://letsencrypt.org/2020/12/21/extending-android-compatibility.html)
- [Production Chain Changes](https://community.letsencrypt.org/t/production-chain-changes/150739)

Your default choice is currently the longer chain that builds to the expired `DST Root CA X3` self-signed certificate which should be compatible with almost all Android devices until 2024. The alternate choice is the shorter chain that builds to the `ISRG Root X1` self-signed certificate which doesn't expire until 2035.

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

There does not seem to be a way to differentiate the chains being served based on application. All websites and applications using leaf certs from the same Intermediate CA will serve the same chain. But it is possible to influence which chain based on the by manipulating the contents of the various Windows trust stores.

The default chain that Windows picks for an LE cert following the expiration of `DST Root CA X3` is actually Let's Encrypt's shorter "alternate" chain which does not include the cross-signed copy of `ISRG Root X1` needed for old Android compatibility. Convincing Windows to serve Let's Encrypt's longer "default" chain that does support old Android devices currently requires a hack that involves un-trusting the legitimate self-signed `ISRG Root X1` on the user account hosting your service. In the case of IIS, that usually means the local SYSTEM account.

There are a number of different ways to make the modifications, but generally speaking the following needs to happen in the cert stores associated with the user running the service.

- Add the [self-signed ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.der) certificate to `Untrusted Certificates`.
- Add the [cross-signed ISRG Root X1](https://letsencrypt.org/certs/isrg-root-x1-cross-signed.der) certificate to `Intermediate Certification Authorities`.
- Add the [current R3](https://letsencrypt.org/certs/lets-encrypt-r3.der) certificate to `Intermediate Certification Authorities`. *(This one may already exist here)*

!!! warning
    This process is an unsupported hack and will partially break certificate validation against sites/services using Let's Encrypt certificates when accessed by software or web browsers on this user account. It should not affect validation for other users on the system.

### Option 1: Manually using PsExec

- Download the 3 certificates linked above (2 versions of ISRG Root X1 and a copy of R3)
- Download Microsoft's [PsExec](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) utility and run the following from an admin prompt to open the Certificate Manager for the SYSTEM user.

```
psexec.exe -i -s certmgr.msc
```

- Navigate to `Untrusted Certificates` and expand
- Right click it, select `All Tasks` - `Import`
- Browse to the **self-signed** ISRG Root X1 you downloaded and complete the wizard to import it
- Navigate to `Intermediate Certification Authorities` and expand
- Right click it, select `All Tasks` - `Import`
- Browse to the **cross-signed** ISRG Root X1 you downloaded and complete the wizard to import it
- Look for an existing copy of `R3` issued by `ISRG Root X1` and expiring in 2025. *(It's okay if there are multiple copies listed)*
- If it doesn't exist, import it the same way you did for the cross-signed ISRG Root X1

### Option 2: Import via Registry File

Many find it easier to import a registry file containing the necessary cert changes. I've created the following two that can allow you to switch back and forth between the "default" and "alternate" chain configurations.

- [LetsEncrypt-DefaultChain-SYSTEM.reg](../assets/files/LetsEncrypt-DefaultChain-SYSTEM.reg.txt)
- [LetsEncrypt-AltChain-SYSTEM.reg](../assets/files/LetsEncrypt-AltChain-SYSTEM.reg.txt)

The first one imports the 3 certs as described in the manual method. The second one deletes them. Download the one you want, remove the `.txt` extension so it becomes `.reg`, and double-click to import it.

### Trigger Cert Chain Rebuild

In order for the cert changes to take effect, the most reliable method is to reboot the server. If you are unable or don't want to reboot, you may also be able to trigger a chain rebuild by causing IIS to rebind the certificate on your site.

On Windows Server 2012 R2 or newer, you can use the following command to rebind the cert as long as you know the certificate thumbprint.  From PowerShell:

```powershell
& $env:SystemRoot\system32\inetsrv\appcmd.exe renew binding /oldcert:THUMBPRINT /newcert:THUMBPRINT
```

On earlier OSes, you can try modifying the binding from IIS Manager or just delete and re-create it. But again, the most reliable way is a reboot.
