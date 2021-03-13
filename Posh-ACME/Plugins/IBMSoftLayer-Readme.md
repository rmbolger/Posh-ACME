# How To Use the IBMSoftlayer DNS Plugin

This plugin works against the [IBM Cloud](https://www.ibm.com/cloud/dns) DNS provider (formerly known as SoftLayer). It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

If you don't already have an API Key setup, login to your account and go to the [Users](https://control.bluemix.net/account/users) page. There should be a `Generate` link in the "API KEY" column. When you click it, you will briefly see a dialog that shows your new API username and key. If you miss it, there should now be a `View` link where the Generate link was before. Click that and make a note of your API username and key values.

## Using the Plugin

There are two possible parameter sets to use with this plugin. The first can only be used on Windows and involves creating a `PSCredential` object for the `IBMCredential` parameter using the API username and key value from earlier. The second uses standard string values for `IBMUser` and `IBMKey` parameter values and can be used on non-Windows.

```powershell
# On Windows, prompt for the credentials
$cred = Get-Credential
$ibmParams = @{ IBMCredential=$cred }

# On non-Windows, just use a regular strings
$ibmParams = @{ IBMUser='SL00000000'; IBMKey='xxxxxxxxxxxx' }

# Request the cert
New-PACertificate example.com -Plugin IBMSoftLayer -PluginArgs $ibmParams
```
