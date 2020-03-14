# How To Use the DNSPod DNS Plugin

This plugin works against the [DNSPod](https://dnspod.com/) provider. It is assumed that you have already setup an account and delegated the domain you will be working against.

## Using the Plugin

### Windows or PS 6.2+

You need to put the account email address and password in a PSCredential object and use it with the `DNSPodCredential` parameter.

```powershell
$pArgs = @{ DNSPodCredential = (Get-Credential) }

New-PACertificate example.com -DnsPlugin DNSPod -PluginArgs $pArgs -DNSSleep 120
```

### Any OS

You need to set `DNSPodUsername` as the account email address and `DNSPodPwdInsecure` as account password.

```powershell
$pArgs = @{
    DNSPodUsername = 'your@mail.example'
    DNSPodPwdInsecure = 'password'
}

New-PACertificate example.com -DnsPlugin DNSPod -PluginArgs $pArgs -DNSSleep 120
```
