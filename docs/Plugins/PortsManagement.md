title: PortsManagement

# How To Use the Ports Management DNS Plugin

This plugin works against the [Ports Management](https://app.ports.management/#/dnsadmin) provider. It is assumed that you already have an account and at least one DNS zone you will be working against.

## Setup

Acquiring a API key for the production API is initiated through your Ports Group representative. As specified in Ports own API docs:
"To get access to the production environment contact your Ports Group representative.

You will receive instructions on how to retrieve your API key from the Ports Management web user interface in a secure way. Note that you will be able to see the API key only once.

You will also be able to configure the privileges of the API access key. That is read-only or read-write access, what part of the organization or what zones the API access key can work with and so forth. It is also possible to get more than one API key with different privileges if required.

In addition, you will need to supply your IP addresses/ranges to be accept listed by Ports Group firewalls. Only accept listed IPs can access the Ports Management API servers."

If you have been given access to the demo environment, you should be able to find a demo API key in the [Ports Management Demo API guide](https://demo.ports.management/pmapi-doc/). The demo environment is only suitable for testing, as you will not be able to validate any certificates using it.

## Using the Plugin

With your API key, pass it to the plugin using the `PortsApiKey` parameter.

```powershell
$pArgs = @{
    PortsApiKey = 'p/5up3r+5ecur3=ap1_k3y-h3re'
}
New-PACertificate example.com -Plugin PortsManagement -PluginArgs $pArgs
```

## Testing the Ports Managment demo environment
For testing against the Demo environment, set the parameter `PortsEnvironment` to 'Demo'
```powershell
Set-PAServer -Name LE_STAGE
New-PAAccount -Contact 'yourname@example.com' -AcceptTOS
$pluginArgs = @{
    PortsApiKey = (Read-Host 'Ports API key' -AsSecureString)
    PortsEnvironment = 'Demo'
}

$challengeArgs = @{
    Domain = 'example.com'
    Account = (Get-PAAccount)
    Token = 'test1'
    Plugin = 'PortsManagement'
    PluginArgs = $pluginArgs
}

Publish-Challenge @challengeArgs
# You can now verify in the Ports Management portal that a record for _acme-challenge has been added to your zone, or use the Get-PortsDnsRecord helper function.

# Clean up
Unpublish-Challenge @challengeArgs

```