# How To Use the Windows DNS Plugin

This plugin works against the Microsoft Windows DNS server. It doesn't matter whether it's hosted on-premises or in the cloud, physical or virtual, domain joined or standalone. As long as it can be managed via the standard [DnsServer PowerShell module](https://docs.microsoft.com/en-us/powershell/module/dnsserver), it should be supported. This does **not** work against [Azure DNS](https://azure.microsoft.com/en-us/services/dns/). Use the Azure plugin for that.

**The DnsServer module is not available on Windows versions prior to Windows 8 and Windows Server 2012. So this plugin will only work on those OSes or newer. Using Zone Scopes requires the Windows 10 or Windows Server 2016 version of the module or newer.**

**This plugin currently does not work on non-Windows OSes in PowerShell Core. [Click here](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) for details.**

## Setup

### DnsServer module

The client machine running Posh-ACME must have the `DnsServer` PowerShell module installed. On Windows Server OSes, this can be installed from Server Manager or via PowerShell as follows.

```powershell
Install-WindowsFeature RSAT-DNS-Server
```

On Windows client OSes, you will need to download and install the appropriate Remote Server Administration Tools (RSAT) for your OS. The installers are historically OS specific. Here are links for [Windows 10](https://www.microsoft.com/en-us/download/details.aspx?id=45520), [Windows 8.1](https://www.microsoft.com/en-us/download/details.aspx?id=39296), [Windows 8](https://www.microsoft.com/en-us/download/details.aspx?id=28972), and [Windows 7](https://www.microsoft.com/en-us/download/details.aspx?id=7887).

*Warning: The vast majority of testing for this plugin was done on Windows 10 and Windows Server 2016. Please submit [issues](https://github.com/rmbolger/Posh-ACME/issues) if you run into problems on downlevel OSes.*

### PSRemoting and New-CimSession

The DnsServer module relies on PowerShell remoting via `New-CimSession` to establish a remote connection to the DNS server. Depending on your environment, PSRemoting might already be enabled. If not, you need to make sure it is working between your client and DNS server before trying to use Posh-ACME.

Typically, the easiest environment to get things working has both client and server domain joined to the same Active Directory or different domains where the client's domain credentials are trusted by the server's AD. In this case, you can try the following to test from the client machine.

```powershell
# test in the context of the current process (current user)
$cs = New-CimSession -ComputerName dnsserver.example.com

# test in the context of a different user
$cs = New-CimSession -ComputerName dnsserver.example.com -Credential (Get-Credential)
```

In environments where one or both of the client and server are not domain joined, you may need to explicitly connect via HTTPS. This may involve extra steps during setup to enable an HTTPS listener on the server. Here is a [decent guide](https://4sysops.com/archives/powershell-remoting-over-https-with-a-self-signed-ssl-certificate/) on getting things setup with a self-signed certificate, though a trusted certificate would work as well. And here is how to test from the client machine.

```powershell
$so = New-CimSessionOption -UseSsl
$cs = New-CimSession -ComputerName dnsserver.example.com -Credential (Get-Credential) -SessionOptions $so
```

Do not proceed until you can successfully establish a CimSession from the client to the DNS server.

### Permissions

Setting permissions on Windows DNS depends on whether the DNS zones are integrated with Active Directory or not. Standalone non-domain joined DNS servers don't really have granular permissions as far as I can tell. The user must be local administrator. AD integrated servers can usually set more granular permissions on a per-zone level or better. Suffice it to say, the account being used to connect must have adequate permissions to add and delete TXT records in the associated zone(s).

## Using the Plugin

In a domain joined environment, the only required parameter is the hostname or IP of the DNS server unless you want the module to use different credentials than what PowerShell is running as. In that case, you would specify credentials and optionally the `-WinUseSSL` switch. Both of those tend to be required for non-domain joined servers.

```powershell
# domain joined environment, no credentials or SSL needed
New-PACertificate example.com -Plugin Windows -PluginArgs @{WinServer='dns1.example.com'}

# standalone environment, adding credentials and SSL flag
$pArgs = @{WinServer='dns1.example.com'; WinCred=(Get-Credential); WinUseSSL=$true}
New-PACertificate example.com -Plugin Windows -PluginArgs $pArgs
```

## Advanced Features

Zone Scopes were added in the Windows Server 2016 version of the DNS server and are now supported in the plugin with the `WinZoneScope` parameter. This is useful if you have a split-brain DNS setup and your external zone is in the non-default scope. Using the parameter requires that your client be running the Windows 10/2016 version of the DnsServer module.

```powershell
# using zone scope in domain joined environment
$pArgs = @{WinServer='dns1.example.com'; WinZoneScope='external'}
New-PACertificate example.com -Plugin Windows -PluginArgs $pArgs
```

VirtualizationInstances are not currently supported. If you use that features and need it supported, please submit an [issue](https://github.com/rmbolger/Posh-ACME/issues) describing your environment.
