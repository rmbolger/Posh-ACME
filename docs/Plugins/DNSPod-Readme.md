# How To Use the DNSPod DNS Plugin

This plugin works against the [DNSPod](https://dnspod.com/) provider. It is assumed that you have already setup an account and created the domain you will be working against.

## Setup

As of November 13, 2020, DNSPod was integrated with Tencent Cloud and slightly changed how their API works. Instead of authenticating with your normal website login credentials, you must create an API token to use instead.

Login to the console and go to the [Key Management](https://console.dnspod.com/account/token) section. Create a new key and make a note of its ID and Token values.

## Using the Plugin

The API key ID is used with the `DNSPodKeyId` string parameter. The key token can be used with `DNSPodKeyToken` as a SecureString or `DNSPodKeyTokenInsecure` as a standard string. The SecureString version should only be used on Windows or any OS with PowerShell 6.2 or later.

There is also a `DNSPodApiRoot` optional parameter that defaults to the API root for dnspod.com. If you are using dnspod.cn, you may specify `https://dnsapi.cn` instead for this parameter.

### Windows or PS 6.2+

```powershell
$pArgs = @{
    DNSPodKeyID = '111'
    DNSPodToken = (Read-Host 'Enter Token' -AsSecureString)
}
New-PACertificate example.com -Plugin DNSPod -PluginArgs $pArgs
```

### Any OS

```powershell
$pArgs = @{
    DNSPodKeyID = '111'
    DNSPodTokenInsecure = 'xxxxxxxxxxxx'
}
New-PACertificate example.com -Plugin DNSPod -PluginArgs $pArgs
```
