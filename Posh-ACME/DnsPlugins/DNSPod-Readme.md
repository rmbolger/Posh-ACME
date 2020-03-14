# How To Use the DNSPod DNS Plugin

This plugin works against the [DNSPod](https://dnspod.com/) provider. It is assumed that you have already setup an account and delegated the domain you will be working against.

## Using the Plugin

There is no setup with this plugin. It uses the same email/password you login to the website with. You may supply them in the `DNSPodCredential` parameter as a PSCredential object. But it can only be used from Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). You may also supply them separately in the `DNSPodUsername` and `DNSPodPwdInsecure` parameters and standard strings.

### Windows or PS 6.2+

```powershell
$pArgs = @{ DNSPodCredential = (Get-Credential) }

New-PACertificate example.com -DnsPlugin DNSPod -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{
    DNSPodUsername = 'your@mail.example'
    DNSPodPwdInsecure = 'password'
}

New-PACertificate example.com -DnsPlugin DNSPod -PluginArgs $pArgs
```
