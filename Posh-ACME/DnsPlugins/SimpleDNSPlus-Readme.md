# How To Use the Simple DNS Plus Plugin

This plugin works against the Simple DNS Plus Servers [Simple DNS Plus](https://simpledns.com/) . 
The assumption is that you have your own DNS Servers using this server software set up. 

## Setup
We need to ensure HTTP API is enabled in Simple DNS Plus

- In the main window
- Click `Tools`
- Click `Options`
- On the left, Scroll down and click `HTTP API`
- Make sure `Enable HTTP API` is checked
- Set URL prefix to default or custom, your choice. eg: https://123.123.123.123/
- Select your desired Method of Authentication. You will need this information. 
- Note the credentials if you use Basic, User ID: will be SdnsUser, and Password will be SdnsSecret later
- Check `Enable CORS`
- `Origins` set to *
- Click OK. 

## Using the Plugin

The only plugin arguments you need are the ServerIP/Name, API User and API secret created earlier.

```powershell
$pArgs = @{SdnsServer='123.123.123.123 or dns.mydomain.com';SdnsUser='xxxxxxxxxxxxx';SdnsSecret='xxxxxxxxxxxxxxxx'}
New-PACertificate example.com -DnsPlugin SimpleDNSPlus -PluginArgs $pArgs
```
