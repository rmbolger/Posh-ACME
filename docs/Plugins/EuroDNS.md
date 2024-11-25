title: EuroDNS

# How To Use the EuroDNS DNS Plugin

This plugin works against the [EuroDNS](https://www.eurodns.com/) DNS provider. This DNS provider has multiple [Partners](https://www.eurodns.com/partners) that provide DNS services to its customers. For our usecase we use a provider called ebrand: [Link](https://ebrand.com/da/). To get an API key, we have to go through an Ebrand contact and they will be communicating with EuroDNS on our behalf.


## Using the Plugin

The API key consist of two values. The X-APP-ID and X-API-KEY. Here are two examples on how you can use them:

```powershell
## The name should be value of X-APP-ID
## The password should be value of X-API-KEY
$pArgs = @{EuroDNS_Creds = Get-Credential}

New-PACertificate example.com -Plugin EuroDNS -PluginArgs $pArgs
```

For a more automated approach (This method assumes you understand the risks and methods to secure the below credentials):

```powershell
$username = "My_X-APP-ID_Value"
$password = "My_X-API-Key_Value" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $password)
$pArgs = @{EuroDNS_Creds = $cred}

New-PACertificate example.com -Plugin EuroDNS -PluginArgs $pArgs
```