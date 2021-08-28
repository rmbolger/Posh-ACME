# How To Use the WebRoot Plugin

This is an HTTP challenge plugin that works by writing challenge files to the local filesystem or a network share. It is generally used when you have an existing web server hosting the content for your domain and you would prefer not to stop it during the certificate issuance process.

## Setup

The ACME server will be validating challenges using a standard HTTP GET query on port 80 to `http://<domain>/.well-known/acme-challenge/<token>`. You will need to know the filesystem path to the root folder that corresponds to your site. For example, the `Default Web Site` in IIS has its web root located at `C:\inetpub\wwwroot`. 

By default, the plugin will write the challenge files to `\.well-known\acme-challenge\` off of the specified root folder. But in some cases, you may have the `http://<domain>/.well-known/acme-challenge/` URL mapped to a specific location on the filesystem and don't want the plugin to add the `\.well-known\acme-challenge` sub-folders. There is a switch described in the next section that will prevent those sub-folders from being created in the specified web root.

If you are using a network share as the web root, make sure PowerShell is running as a user with permissions to write to that share. There is currently no way to specify explicit credentials.

## Using the Plugin

The web root is specified using the `WRPath` parameter. If you don't want the plugin to put the files in a `\.well-known\acme-challenge` sub-folder, you must also specify `WRExactPath = $true` in your plugin args.

### Default functionality

```powershell
$pArgs = @{ WRPath = 'C:\inetpub\wwwroot' }
New-PACertificate example.com -Plugin WebRoot -PluginArgs $pArgs
```

## No sub-folder example

```powershell
$pArgs = @{
    WRPath = 'C:\inetpub\wwwroot\.well-known\acme-challenge'
    WRExactPath = $true
}
New-PACertificate example.com -Plugin WebRoot -PluginArgs $pArgs
```
