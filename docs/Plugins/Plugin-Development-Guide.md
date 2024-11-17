# Plugin Development Guide

## Introduction

A validation plugin for Posh-ACME is a standard PowerShell PS1 script file located in the module's `Plugins` folder. It can also be in a folder outside the module and referenced using the `POSHACME_PLUGINS` environment variable. The file name is what users will use to reference it when specifying a plugin, so it should be related to the provider it is publishing against.

All plugins must contain a function called `Get-CurrentPluginType` which returns a string indicating the type of ACME challenge they support. Posh-ACME currently supports the `dns-01` and `http-01` challenge types.

DNS plugins must contain the following additional functions:

- `Add-DnsTxt`
- `Remove-DnsTxt`
- `Save-DnsTxt`

HTTP plugins must contain the following additional functions:

- `Add-HttpChallenge`
- `Remove-HttpChallenge`
- `Save-HttpChallenge`

The easiest way to get started is to make a copy of `_Example-DNS.ps1` or `_Example-HTTP.ps1` depending on the type of plugin you are making and rename it for your purposes.

**Pull Requests for new plugins are quite welcome.**


## Function Details

### `Add-DnsTxt` and `Remove-DnsTxt`

These are responsible for adding/removing TXT records to/from a DNS server/provider. There are two mandatory and positional string parameters, `$RecordName` and `$TxtValue`. RecordName is the fully qualified domain name (FQDN) of the record we will be adding a TXT value for. TxtValue is the actual value that will be set in the TXT record. Do not modify or remove these first
two parameters.

Additional parameters should be added as necessary for the specific DNS provider such as credentials or API keys. In addition to standard PowerShell naming standards, their names must also not conflict with any other plugin's parameters. A good way to do that is to use a unique prefix on all of the parameters. It doesn't have to match the plugin name exactly as long as it's unique and reasonably related to the plugin. Common parameters that can be shared between this plugin's functions should be named the same as each other.

The last parameter should always be `$ExtraParams` with the `ValueFromRemainingArguments` parameter attribute. This allows callers to [splat](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-5.1) the combined collection of plugin parameters to each plugin without errors for parameters that don't exist.

Many DNS providers will only need the Add and Remove functions. In those cases, remember to remove all but the `$ExtraParams` parameter in the Save function and just leave the function body empty. For other providers, it is may be more efficient to stage changes in bulk and then perform what is effectively a Save or Commit operation on those changes. In those cases, implement the Save function as described below.

### `Add-HttpChallenge` and `Remove-HttpChallenge`

These are responsible for publishing/unpublishing the ACME challenge body text at a specific HTTP URL. There are three mandatory and positional string parameters, `$Domain`, `$Token`, and `$Body`. Domain and Token are what the validation server will use to build the URL it will check against (`http://<Domain>/.well-known/acme-challenge/<Token>`). Body is the text value it expects to get in response to that query. Do not modify or remove these first three parameters.

Additional parameters should be added as necessary for the specific HTTP provider such as filesystem paths, credentials, or API keys. In addition to standard PowerShell naming standards, their names must also not conflict with any other plugin's parameters. A good way to do that is to use a unique prefix on all of the parameters. It doesn't have to match the plugin name exactly as long as it's unique and reasonably related to the plugin. Common parameters that can be shared between this plugin's functions should be named the same as each other.

The last parameter should always be `$ExtraParams` with the `ValueFromRemainingArguments` parameter attribute. This allows callers to [splat](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-5.1) the combined collection of plugin parameters to each plugin without errors for parameters that
don't exist.

Many HTTP providers will only need the Add and Remove functions. In those cases, remember to remove all but the `$ExtraParams` parameter in the Save function and just leave the function body empty. For other providers, it is may be more efficient to stage changes in bulk and then perform what is effectively a Save or Commit operation on those changes. In those cases, implement the Save function as described below.

### `Save-DnsTxt` and `Save-HttpChallenge`

These functions are optional for DNS/HTTP plugins where it is more efficient to stage changes in bulk before Saving or Committing the changes. There are no required parameters except `$ExtraParams` which should always be last and have the `ValueFromRemainingArguments` parameter attribute.

### Parameter Types

Try to limit parameters to simple data types like `[string]`, `[int]`, and `[switch]`. Arrays and Hashtables are fine as long as the contents are also simple types. Hashtables in particular should not be nested. The parameters should be able to convert nicely back and forth using `Convert-ToJson` and `Convert-FromJson`.

Secrets such as passwords and API keys/tokens should use `[SecureString]` or `[PSCredential]` parameters even if you ultimately need them in plain text within the plugin. This ensures the values are encrypted when saved to disk for later renewals. Here are some examples for how to convert them back to plain text in the plugin code.

```powershell
# get the username and password from a PSCredential called $cred
$username = $cred.Username
$password = $cred.GetNetworkCredential().Password

# get the plain text from a SecureString called $secString
$plainText = [pscredential]::new('a',$secString).GetNetworkCredential().Password
```

## Usage Guides

In addition to the native function help, it can be very helpful to new users to have a plugin specific readme. It should be a [Markdown](https://www.markdowntutorial.com/) formatted file in the [docs/Plugins](https://github.com/rmbolger/Posh-ACME/tree/main/docs/Plugins) folder called `<PluginName>.md`. It's usually easiest to copy an existing guide and modify it. The `title:` field at the top of the file should match the name of the plugin including capitalization.

!!!note
    You may notice there are some Markdown files for other plugins in the main Plugins folder called `<PluginName>-Readme.md`. These exist for legacy reasons before the docs website was around and are not necessary for new plugins.

For people who may be setting up automation against their provider for the first time, it can be helpful to add guidance on creating service accounts, limited access roles, or any prerequisite setup that the plugin requires to work properly. It should also have a section with an example on how to use the plugin with `New-PACertificate`.


## General Development Tips and Tricks

### No Write-Host

Unless your plugin requires interactive user input which should be rare, do not use `Write-Host` to display informational messages or debug output. Use `Write-Verbose` for messages you would want a potential user to see. Use `Write-Debug` for things only the plugin developer would likely care about or a user trying to troubleshoot a plugin that is not working.

When testing your module, use `-Verbose` to see your verbose messages. And run `$DebugPreference = 'Continue'` to make the debug messages show up without prompting for confirmation *(which happens if you use `-Debug`)*.

### No Pipeline Output

Do not output any objects to the pipeline from your plugin. This will interfere with scripts and workflows that use the normal output of public functions. You can use `Out-Null` on internal calls that would normally output to the pipeline when you don't care about that data.

### UseBasicParsing

Any time you call `Invoke-WebRequest` or `Invoke-RestMethod`, you should always add `@script:UseBasic` to the end.

By default in PowerShell 5.1, those two functions use Internet Explorer's DOM parser to process the response body which can cause errors in cases where IE is not installed or hasn't gone through its first-run sequence yet. Both functions have a `-UseBasicParsing` parameter that switches the parser to a PowerShell native parser and is the new default functionality in PowerShell 6+. The parameter is also deprecated because they don't plan on bringing back IE DOM parsing in future PowerShell versions. So the module creates a variable when it is first loaded that checks whether `-UseBasicParsing` is still available or not and adds it to the `$script:UseBasic` hashtable. That way, you can just [splat](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting) it on all your calls to those two functions which will future proof your plugin.

### Testing Plugins

If the module is already loaded in the session, you will need to re-import it using `Import-Module -Force`. There is a helper script called `instdev.ps1` in the root of the git repository that can make this process a lot easier as you are developing the plugin.

First make sure any existing copies of the module are uninstalled (or at least don't reside in your `$env:PSModulePath`). Clone the git repository (or your fork) to a folder on your local system and add your plugin file to the `Posh-Acme\Plugins` folder if it's not already there. Open a new PowerShell session to the repository root folder and run `.\instdev.ps1` which will do the following:

- Copy the module files to the current user's default PowerShell modules folder.
- Run `Import-Module Posh-ACME -Force`
- Display the available module commands

If there are no problems, your plugin should now be listed in the output of `Get-PAPlugin`.

Testing a plugin can be done without requesting a new certificate. All you need is an existing ACME account created with `New-PAAccount` and the `Publish-Challenge`, `Unpublish-Challenge`, and `Save-Challenge` functions. They call the Add, Remove, and Save functions from the plugin. Here are some examples of how I generally call them while testing.

```powershell
$DebugPreference = 'Continue'
$pArgs = @{MyParam1='asdf';MyParam2='qwer'}

# multiple calls to publish/unpublish are generally more useful for DNS plugins
Publish-Challenge example.com (Get-PAAccount) test1 MyPlugin $pArgs -Verbose
Publish-Challenge example.com (Get-PAAccount) test2 MyPlugin $pArgs -Verbose
Publish-Challenge example.com (Get-PAAccount) test3 MyPlugin $pArgs -Verbose

# save is only necessary if your plugin implements it
Save-Challenge MyPlugin $pArgs -Verbose

Unpublish-Challenge example.com (Get-PAAccount) test1 MyPlugin $pArgs -Verbose
Unpublish-Challenge example.com (Get-PAAccount) test2 MyPlugin $pArgs -Verbose
Unpublish-Challenge example.com (Get-PAAccount) test3 MyPlugin $pArgs -Verbose

# save is only necessary if your plugin implements it
Save-Challenge MyPlugin $pArgs -Verbose
```

Alternatively, you can [dot source](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-5.1#script-scope-and-dot-sourcing) the plugin file and call the functions directly. But this can be difficult if the functions depend on module-scoped variables like `$script:UseBasic` or internal module functions. Also, remember to dot source again each time you make a change to the plugin.

## DNS Specific Tips and Tricks

### Multiple TXT Values Per Record

It is both supported and expected that a given TXT record may have multiple values. It's most common with wildcard certificates that contain both the wildcard name (`*.example.com`) and the root domain (`example.com`). Both names require TXT records be added for the same FQDN (`_acme-challenge.example.com`). This can also happen if the user is using CNAME challenge aliases.

The Add/Remove functions need to support all potential states of the particular TXT record. But how the record is represented by a given provider seems to vary. Some represent it as a single record with multiple values that you need to add to or remove from. Others have distinct records for each value that can be created/deleted individually. So make sure you can both create a new record that doesn't exist *and* add a value to a record that already does.

### Remove Only Specific TxtValue

Related to having multiple TXT values per record, the remove function must not blindly delete any record that matches `$RecordName`. It should be able to remove only the `$TxtValue` on a record that may have multiple values. But if the record only contains a single value, the record should be deleted entirely.

### Zone Matching

A particular DNS provider may be hosting both domain apex zones (`example.com`) and sub-zones (`sub1.example.com`). One of the first things a plugin usually has to do is figure out which zone `$RecordName` needs to be added to. This should be the deepest sub-zone that would still contain `$RecordName`. Here are some examples assuming only the two previously mentioned zones exist.

`$RecordName`                                    | Matching Zone
-------------                                    | -------------
_acme-challenge.example.com                      | example.com
_acme-challenge.site1.example.com                | example.com
_acme-challenge.sub1.example.com                 | sub1.example.com
_acme-challenge.site1.sub1.example.com           | sub1.example.com
_acme-challenge.site1.sub3.sub2.sub1.example.com | sub1.example.com

Many of the existing plugins have a helper function to handle this. Copy and modify their code where it makes sense but make sure helper function names are unique.

### Relative Record Names

Many providers will end up needing you to provide a record's relative/short name such as `_acme-challenge` or `_acme-challenge.www` rather than the fully-qualified domain provided by `$RecordName`. To do this properly, you must first know the zone name that would contain the record. Once you have it, use the following method to separate the relative name from the zone name.

```powershell
# assumes $zoneName contains the zone name containing the record
$recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
```

Keep in mind that there are cases where `$RecordName` and `$zoneName` can be identical. The code above will set `$recShort` to an empty string. Depending on the provider, this may not be the proper way to reference zone apex records. Some providers expect you to use `@`, others may want the full zone name like `example.com`. So if your provider expects something other than an empty string, make sure you account for it. Here's an example:

```powershell
if ($recShort -eq [string]::Empty) {
    $recShort = '@'
}
```

### DNS Aliases and Domain Apex

Don't forget to test your functions against the domain apex which can happen when users are using DNS challenge aliases.

```powershell
# The my.cname.tld record doesn't actually need to exist for the test to work.
# The plugin will only be writing to example.com
$publishParams = @{
    Domain = 'my.cname.tld'
    Account = (Get-PAAccount)
    Token = 'fake-token'
    Plugin = 'MyPlugin'
    PluginArgs = $pArgs
    DnsAlias = 'example.com'
    Verbose = $true
}
Publish-Challenge @publishParams
Unpublish-Challenge @publishParams
```

### Deriving Object IDs

Many providers assign ID values to object types like zones and records that you need to use to manipulate those objects. A user should ideally not have to know or provide any zone, record, or object IDs in order to use the plugin. All of that should be discovered by the plugin code and the only thing the user should need to provide is whatever credentials or tokens the API requires for authentication.

In the rare cases that you do need the user to provide something like a zone ID, make sure you allow for multiple values. A single certificate can contain names from many different zones and the plugin parameters that get passed to the plugin are the same for each TXT record that needs to be created.

### Trailing Dots

Be aware how your particular DNS provider represents zone and record names. Some include the trailing dot (`example.com.`). Others don't. This can affect string matching when finding zones and existing records.

### Internationalized Domain Name (IDN)

Many DNS providers and registrars support [IDN domains](https://en.wikipedia.org/wiki/Internationalized_domain_name) which contain non-ascii unicode characters (or even emojis). When using IDN domains with ACME, the IDN names must be specified as [Punycode](https://en.wikipedia.org/wiki/Punycode). But the DNS providers may still send or receive the unicode version of the name. Particularly if your provider is not US-based, be aware of and try to account for how the provider handles IDN names.

The .NET [System.Globalization.IdnMapping](https://docs.microsoft.com/en-us/dotnet/api/system.globalization.idnmapping) class can help convert back and for between IDN and punycode names like this:

```powershell
# create an instance of the class
$idn = [System.Globalization.IdnMapping]::new()

# convert an IDN name to punycode
$idn.GetAscii('bücher.example')

# convert a punycode name back to IDN
$idn.GetUnicode('xn--bcher-kva.example')
```

## HTTP Specific Tips and Tricks

### Validation Timing

When DNS plugins are used, there's a user customizable sleep timer between when the TXT records are published and the module asks the ACME server to validate those records because records are not typically available instantaneously worldwide. However, that sleep timer does not exist when an order is only using HTTP plugins because HTTP resources are typically available instantly.

If your particular HTTP provider requires a delay between when the challenges are published and when they are validated, you should add that delay in the `Save-HttpChallenge` function of your plugin.

## Migrating DNS Plugins from 3.x to 4.x

In case you have been using your own private DNS plugin in 3.x, here's how to migrate it to the 4.x format.

* Add `function Get-CurrentPluginType { 'dns-01' }` to the top of the file.
* Replace instances of `Add-DnsTxt<Name>` with `Add-DnsTxt`
* Replace instances of `Remove-DnsTxt<Name>` with `Remove-DnsTxt`
* Replace instances of `Save-DnsTxt<Name>` with `Save-DnsTxt`
* Replace instances of `-DnsPlugin` with `-Plugin` in usage guides.
