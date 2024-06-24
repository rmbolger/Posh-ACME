title: DNSPod

# How To Use the DNSPod DNS Plugin

This plugin works against the [DNSPod](https://dnspod.com/) provider. It is assumed that you have already setup an account and created the domain you will be working against.

!!! warning
    DNSPod is now integrated with Tencent Cloud and will eventually be disabling the legacy DNSPod Token authentication this plugin uses. It is recommended to switch to the [TencentDNS](TencentDNS.md) plugin instead.

## Setup

As of November 13, 2020, DNSPod was integrated with Tencent Cloud and slightly changed how their API works. Instead of authenticating with your normal website login credentials, you must create an API token to use instead.

Login to the console and go to the [Key Management](https://console.dnspod.com/account/token) section. Create a new key and make a note of its ID and Token values.

## Using the Plugin

The API key ID is used with the `DNSPodKeyId` string parameter. The key token is used with `DNSPodKeyToken` as a SecureString.

!!! warning
    The `DNSPodKeyTokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

There is also a `DNSPodApiRoot` optional parameter that defaults to the API root for dnspod.com. If you are using dnspod.cn, you may specify `https://dnsapi.cn` instead for this parameter.

```powershell
$pArgs = @{
    DNSPodKeyID = '111'
    DNSPodKeyToken = (Read-Host 'Enter Token' -AsSecureString)
}
New-PACertificate example.com -Plugin DNSPod -PluginArgs $pArgs
```
