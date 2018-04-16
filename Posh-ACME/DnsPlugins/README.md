# Writing a DNS Plugin for Posh-ACME

A DNS plugin for Posh-ACME is a standard Powershell PS1 script file located in the module's `DnsPlugins` folder. It must contain the following function definitions where `XXXX` is a unique name for the plugin:

- `Add-DnsTxtXXXX`
- `Remove-DnsTxtXXXX`
- `Save-DnsTxtXXXX`

The name must not contain spaces and only consist of letters and numbers. The PS1 file must use the same name for its filename. The easiest way to get started is to make a of copy the `_Example.ps1` file and name it something related to your DNS provider which adheres to the requirements.

Once you have settled on the name, open the file and modify the 3 main function names to match the plugin name. So if your plugin name was `Flurbog.ps1`, you'd modify the functions as follows:

- `Add-DnsTxtFlurbog`
- `Remove-DnsTxtFlurbog`
- `Save-DnsTxtFlurbog`

**Pull Requests for new plugins are quite welcome.**

## Function Details

### `Add-DnsTxtXXXX` and `Remove-DnsTxtXXXX`

These are responsible for adding/removing TXT records to/from the DNS server. There are two mandatory and positional string parameters, `$RecordName` and `$TxtValue`. RecordName is the fully qualified domain name (FQDN) of the record we will be adding a TXT value for. TxtValue is the actual value that will be set in the TXT record. Do not modify or remove these first
two parameters.

Additional parameters should be added as necessary for the specific DNS provider. In addition to standard Powershell naming standards, their names must also not conflict with any other plugin's parameters. A good way to do that is to use a unique prefix on all of the parameters. It doesn't have to match the plugin name exactly as long as it's unique and reasonably related to the plugin. Common parameters that can be shared between this plugin's functions should be named the same as each other.

The last parameter should always be `$Splat` with the `ValueFromRemainingArguments` parameter attribute. This allows callers to [splat](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-5.1) the combined collection of plugin parameters to each plugin without errors for parameters that
don't exist.

**IMPORTANT:** Certificate orders that contain a wildcard domain (`*.example.com`) and the root domain (`example.com`) will require two TXT records to be added for the same FQDN (`_acme-challenge.example.com`). In Remove-DnsTxtXXXX, be sure to only remove the value passed in via `$TxtValue` and not all records for the `$RecordName` FQDN.

Many DNS providers will only need the Add and Remove functions. In those cases, remember to remove all but the `$Splat` parameter in the Save function and just leave the function body empty. For other providers, it is may be more efficient to stage changes in bulk and then perform what is effectively a Save or Commit operation on those changes. In those cases, implement the Save function as described below.

### `Save-DnsTxtXXXX`

This function is optional in a DNS plugin and only used for DNS providers where it is more efficient to stage changes in bulk before Saving or Committing the changes. There are no required parameters except `$Splat` which should always be last and have the `ValueFromRemainingArguments` parameter attribute.


## Testing Plugins

Plugins can be tested using `Publish-DnsChallenge`, `Unpublish-DnsChallenge`, and `Save-DnsChallenge`. They call the Add, Remove, and Save functions respectively. Use `Get-Help` on those functions for more information on how to use them.

You can also [dot source](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-5.1#script-scope-and-dot-sourcing) the plugin file and call the functions directly. Just remember to dot source again each time you make a change to the plugin.
