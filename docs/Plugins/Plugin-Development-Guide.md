# Plugin Development Guide

## Introduction

A plugin is a PowerShell `.ps1` script file. Put the file in the module `Plugins` folder, or store it in another folder and reference that folder with the `POSHACME_PLUGINS` environment variable.

Users select a plugin by file name without the extension. Choose a file name that clearly matches the provider.

All plugins must define `Get-CurrentPluginType`. This function returns the ACME challenge type supported by the plugin. Posh-ACME currently supports `dns-01` and `http-01`. Since version v4.33.0, the `dns-01` challenge type also implies support for `dns-account-01` and `dns-persist-01` DNS challenge variants. Those don't need to be explicitly supported.

DNS plugins must also define:

- `Add-DnsTxt`
- `Remove-DnsTxt`
- `Save-DnsTxt`

HTTP plugins must also define:

- `Add-HttpChallenge`
- `Remove-HttpChallenge`
- `Save-HttpChallenge`

To start quickly, copy `_Example-DNS.ps1` or `_Example-HTTP.ps1` and rename the copy.

!!! note
    Pull Requests for new plugins are quite welcome.


## Function Details

### `Add-DnsTxt` and `Remove-DnsTxt`

These functions add and remove TXT records in a DNS provider.

Both functions must include these first two parameters exactly as shown:

```
[Parameter(Mandatory,Position=0)]
[string]$RecordName,
[Parameter(Mandatory,Position=1)]
[string]$TxtValue,
```

Do not rename, reorder, remove, or change the type of these two parameters.

Add provider-specific parameters as needed, for example credentials or API keys. Follow normal PowerShell naming conventions. Also ensure parameter names do not conflict with parameter names used by other plugins.

Use a unique provider prefix for provider-specific parameters. The prefix does not need to match the plugin name exactly, but it should be unique and clearly related.

If two or more functions in the same plugin use the same meaning for a parameter, use the same parameter name in each function.

The last parameter must be `$ExtraParams` with the `ValueFromRemainingArguments` attribute as shown below. This allows callers to [splat](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting) a combined parameter set without failing on extra keys.

```
[Parameter(ValueFromRemainingArguments)]
$ExtraParams
```

Many DNS providers only need `Add-DnsTxt` and `Remove-DnsTxt`.

- If no explicit commit step is required, keep `Save-DnsTxt` with only `$ExtraParams` and an empty function body.
- If the provider supports staged updates, implement `Save-DnsTxt` to commit those staged changes.

### `Add-HttpChallenge` and `Remove-HttpChallenge`

These functions publish and remove ACME challenge content at an HTTP endpoint.

Both functions must include these first three parameters exactly as shown:

```
[Parameter(Mandatory,Position=0)]
[string]$Domain,
[Parameter(Mandatory,Position=1)]
[string]$Token,
[Parameter(Mandatory,Position=2)]
[string]$Body,
```

The validation server checks this URL pattern:

`http://<Domain>/.well-known/acme-challenge/<Token>`

The response body at that URL must match `$Body`.

Do not rename, reorder, remove, or change the type of these three parameters.

Add provider-specific parameters as needed, for example file paths, credentials, or API keys. Use PowerShell naming conventions and avoid conflicts with parameter names from other plugins.

As with DNS plugins, use a unique provider prefix where practical, and keep shared parameter names consistent across functions in the same plugin.

The last parameter must be `$ExtraParams` with the `ValueFromRemainingArguments` attribute as shown below. This allows callers to [splat](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting) a combined parameter set without failing on extra keys.

```
[Parameter(ValueFromRemainingArguments)]
$ExtraParams
```

Many HTTP providers only need `Add-HttpChallenge` and `Remove-HttpChallenge`.

- If no explicit commit step is required, keep `Save-HttpChallenge` with only `$ExtraParams` and an empty function body.
- If the provider supports staged updates, implement `Save-HttpChallenge` to commit those staged changes.

### `Save-DnsTxt` and `Save-HttpChallenge`

These save functions are optional. Use them when the provider workflow is stage first, then commit.

Copy the provider specific parameters to this function and include the `$ExtraParams` parameter last with the `ValueFromRemainingArguments` attribute.

### Parameter Types

Prefer simple parameter types such as `[string]`, `[int]`, and `[switch]`.

Arrays and hashtables are supported if their contents are also simple types. Do not nest hashtables.

Parameter values should serialize and deserialize cleanly with `ConvertTo-Json` and `ConvertFrom-Json`.

For secrets such as passwords and API keys or tokens, use `[SecureString]` or `[PSCredential]`, even if the plugin later needs plain text. This keeps saved renewal data encrypted at rest.

Here are examples for converting secret values back to plain text:

```powershell
# get the username and password from a PSCredential called $cred
$username = $cred.Username
$password = $cred.GetNetworkCredential().Password

# get the plain text from a SecureString called $secString
$plainText = [pscredential]::new('a',$secString).GetNetworkCredential().Password
```

## Usage Guides

Please include a plugin-specific usage guide by creating a [Markdown](https://www.markdowntutorial.com/) file named `<PluginName>.md` in [docs/Plugins](https://github.com/rmbolger/Posh-ACME/tree/main/docs/Plugins). To save time, copy an existing plugin guide and edit it.

Set the `title:` value at the top of the guide to match the plugin name exactly, including capitalization.

For users who are automating against a provider for the first time, include prerequisite setup steps. Typical examples are service account creation, least-privilege role assignment, and required API enablement.

Include at least one usage example that shows how to use the plugin with `New-PACertificate`.


## General Development Tips and Tricks

### No Write-Host

Do not use `Write-Host` for informational or debug output. Use `Write-Verbose` for messages intended for plugin users. Use `Write-Debug` for developer-focused troubleshooting details. Interactive prompts should be rare. If your plugin does not require user input, avoid interactive output patterns.

When testing, use `-Verbose` to display verbose output. To display debug output without confirmation prompts, run `$DebugPreference = 'Continue'`.

### No Pipeline Output

Do not write plugin objects to the pipeline. Pipeline output from plugin internals can interfere with scripts that rely on normal output from public module functions. If an internal call returns objects that you do not need, pipe that call to `Out-Null`.

### UseBasicParsing

When calling `Invoke-WebRequest` or `Invoke-RestMethod`, always append `@script:UseBasic`.

In Windows PowerShell 5.1, these cmdlets may use the Internet Explorer DOM parser by default. This can fail if Internet Explorer is unavailable or not initialized. The `-UseBasicParsing` switch uses a PowerShell-native parser. In PowerShell 6+, that behavior is already the default and the switch is deprecated.

Posh-ACME initializes `$script:UseBasic` when the module loads. The variable contains `-UseBasicParsing` only when that switch is supported. Splatting `@script:UseBasic` keeps plugin web calls compatible across supported PowerShell versions.

### Testing Plugins

If the module is already loaded in the current session, re-import it with `Import-Module -Force`. When editing from a clone of the git repo, you can use `instdev.ps1` in the repository root instead.

Before running it, ensure existing installed copies of the module are removed or not present in `$env:PSModulePath`. Clone the repository (or your fork), place your plugin file in `Posh-Acme\Plugins` if needed, open a new PowerShell session in the repository root, and run `.\instdev.ps1`.

The script performs these actions:

- Copy the module files to the current user's default PowerShell modules folder.
- Run `Import-Module Posh-ACME -Force`
- Display the available module commands

If the import succeeds, `Get-PAPlugin` should list your plugin.

You can test plugin behavior without requesting a new certificate. Ensure you have an existing ACME account created with `New-PAAccount` first. Then, use these commands to test a standard multi-SAN cert validation.

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

You can also [dot source](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-5.1#script-scope-and-dot-sourcing) the plugin file and call plugin functions directly.

!!! note
    Direct dot-sourcing can be difficult when the plugin depends on module-scoped variables such as `$script:UseBasic` or private module functions. If you choose dot-sourcing, load the file again after each plugin edit.

## DNS Specific Tips and Tricks

### Multiple TXT Values Per Record

TXT records can contain multiple values. Plugins must support this. This is common for wildcard certificates that include both `*.example.com` and `example.com`. Both names require distinct validation data at `_acme-challenge.example.com`. This can also happen when users use CNAME challenge aliases.

Provider APIs represent multi-value TXT records differently:

- Some APIs use one record object with multiple values.
- Some APIs use separate record objects, one per value.

Your Add and Remove functions must handle all relevant states, including:

- Creating a TXT record that does not exist.
- Adding a value to an existing TXT record.

### Remove Only Specific TxtValue

When multiple values exist on the same TXT record, do not delete by `$RecordName` alone. The remove function must remove only the requested `$TxtValue`. If the TXT record contains only that one value, delete the record.

### Zone Matching

A DNS provider can host both apex zones (for example, `example.com`) and sub-zones (for example, `sub1.example.com`). The plugin must identify which zone contains `$RecordName`. Use the deepest matching zone that still contains the record.

The table below assumes only `example.com` and `sub1.example.com` exist:

`$RecordName`                                    | Matching Zone
-------------                                    | -------------
_acme-challenge.example.com                      | example.com
_acme-challenge.site1.example.com                | example.com
_acme-challenge.sub1.example.com                 | sub1.example.com
_acme-challenge.site1.sub1.example.com           | sub1.example.com
_acme-challenge.site1.sub3.sub2.sub1.example.com | sub1.example.com

Many existing plugins include helper functions for zone matching. Reuse and adapt them where appropriate.

### Relative Record Names

Some provider APIs require a relative (short) record name such as `_acme-challenge` or `_acme-challenge.www`, not a full FQDN. To calculate the relative name, first determine the containing zone name. Then separate the record from the zone with this pattern:

```powershell
# assumes $zoneName contains the zone name containing the record
$recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
```

`$RecordName` and `$zoneName` can be identical. In that case, the code above sets `$recShort` to an empty string. This works for some providers, but others use a specific character to represent an apex record such as `@` or the full zone name. If your provider does not accept an empty apex name, map the empty value to the required format. Example:

```powershell
if ($recShort -eq [string]::Empty) {
    $recShort = '@'
}
```

### DNS Aliases and Domain Apex

Test domain apex behavior, by simulating using DNS challenge aliases.

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

### Future-Proof for dns-persist-01

The `dns-persist-01` challenge standard is still in development. It is recommended to make new DNS plugins compatible with it.

The key difference from `dns-01` is `$TxtValue` input quoting:

- `dns-persist-01` values will arrive already wrapped in double quotes.
- `dns-01` values will arrive unquoted.

This difference can affect string matching against provider API results, so plugin logic should handle both forms.

Example test for persist support:

```powershell
# The actual values for AccountUri and IssuerDomainName don't matter
# as long as they're not empty
$pubParams = @{
    Domain = 'example.com'
    AccountUri = 'fakeaccount'
    IssuerDomainName 'fakeissuer'
    AllowWildcard = $true
    Plugin = 'InfomaniakV2'
    PluginArgs = $pArgs
    Verbose = $true
}
Publish-DnsPersistChallenge @pubParams
Unpublish-DnsPersistChallenge @pubParams
```

Some APIs normalize quotes automatically. Others do not. If needed, normalize the incoming `$TxtValue` to ensure it is quoted:

```powershell
# Normalize the TxtValue to ensure it is wrapped in quotes
if ($TxtValue -notmatch '^".*"$') {
    $TxtValue = "`"$TxtValue`""
}
```

### Deriving Object IDs

Many providers assign object IDs (such as zone IDs and record IDs) that are required for API operations. Prefer automatic discovery of these IDs in plugin code. Users should only need to provide only authentication material, such as credentials or tokens.

If user-supplied IDs are required, support multiple values. A single certificate can include names from multiple zones, and the same plugin argument set is reused for each challenge record.

### Trailing Dots

Check how your provider represents zone and record names. Some APIs include trailing dots (for example, `example.com.`). Others do not. Account for this in all matching logic for zones and existing records.

### Internationalized Domain Name (IDN)

Many DNS providers and registrars support [IDN domains](https://en.wikipedia.org/wiki/Internationalized_domain_name), which contain non-ASCII Unicode characters. For ACME operations, IDN names must be provided as [Punycode](https://en.wikipedia.org/wiki/Punycode). Provider APIs may still return or accept Unicode labels.

Make sure plugin logic handles the provider's IDN behavior correctly. Use .NET `System.Globalization.IdnMapping` to convert between Unicode and Punycode as necessary:

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

For DNS plugins, Posh-ACME includes a user-configurable wait period before validation. This helps account for DNS propagation time. For HTTP-only orders, that DNS wait period is not used because HTTP content is usually available immediately.

If your HTTP provider still requires a delay before validation succeeds, add that delay in `Save-HttpChallenge`.

## Migrating DNS Plugins from 3.x to 4.x

Use this checklist to migrate a private DNS plugin from 3.x to 4.x.

- Add `function Get-CurrentPluginType { 'dns-01' }` at the top of the file.
- Replace `Add-DnsTxt<Name>` with `Add-DnsTxt`.
- Replace `Remove-DnsTxt<Name>` with `Remove-DnsTxt`.
- Replace `Save-DnsTxt<Name>` with `Save-DnsTxt`.
- Replace `-DnsPlugin` with `-Plugin` in usage guides.
