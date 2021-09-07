title: IBMSoftLayer

# How To Use the IBMSoftlayer DNS Plugin

This plugin works against the [IBM Cloud](https://www.ibm.com/cloud/dns) DNS provider (formerly known as SoftLayer). It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

If you don't already have an API Key setup, login to your account and go to the [Users](https://control.bluemix.net/account/users) page. There should be a `Generate` link in the "API KEY" column. When you click it, you will briefly see a dialog that shows your new API username and key. If you miss it, there should now be a `View` link where the Generate link was before. Click that and make a note of your API username and key values.

## Using the Plugin

The API username and key are used with the `IBMCredential` parameter as a PSCredential object where the key is the password.

*NOTE: The `IBMUser` and `IBMKey` parameters are deprecated and will be removed in the next major module version. Please migrate to the Secure parameter set.*

```powershell
$pArgs = @{ IBMCredential = (Get-Credential) }
New-PACertificate example.com -Plugin IBMSoftLayer -PluginArgs $pArgs
```
