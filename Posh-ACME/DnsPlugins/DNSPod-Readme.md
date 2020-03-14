# How To Use the Dnspod DNS Plugin

This plugin works against the [Dnspod](https://dnspod.com/) provider. It is assumed that you have already setup an account and delegated the domain you will be working against.

## Using the Plugin

### Windows or PS 6.2+

You need to put the account email address and password in a PSCredential object and use it with the `DnspodCredential` parameter.

```powershell
$pArgs = @{ DnspodCredential = (Get-Credential) }

New-PACertificate example.com -DnsPlugin Dnspod -PluginArgs $pArgs -DNSSleep 120
```

### Any OS

You need to set `DnspodUsername` as the account email address and `DnspodPwdInsecure` as account password.

```powershell
$pArgs = @{
    DnspodUsername = 'your@mail.example'
    DnspodPwdInsecure = 'password'
}

New-PACertificate example.com -DnsPlugin Dnspod -PluginArgs $pArgs -DNSSleep 120
```
