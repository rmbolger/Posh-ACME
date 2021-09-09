# Find Deprecated PluginArgs

Posh-ACME 4.8 has deprecated many of the old "insecure" plugin parameter sets used to be necessary on non-Windows machines running early versions of PowerShell 6. This means that when Posh-ACME 5.0 is eventually released, certificate orders renewing with those parameter sets will stop working if they haven't been replaced by a "secure" parameter set. So it would be wise to update those parameters sooner rather than later.

In most cases, migrating to a secure parameter set is just a matter of using a SecureString version of a token, key, or password instead of a standard String object. It might also mean using a PSCredential object instead of separate Username and Password parameters. The [usage guide](../Plugins/index.md) for each plugin will detail exactly what to use.

If you have a lot of accounts or orders, particularly if they use different plugins, it may be a tedious process to find the orders that are using the deprecated parameters. Here's a function to help find those orders more easily.

!!! warning
    The function assumes you've already installed Posh-ACME 4.8 or later which may also be required in order to migrate to the secure parameter sets that were added in 4.8.

```powershell
function Find-DeprecatedPluginArgs {
    [CmdletBinding()]
    param()

    # build a list of parameter names that we know are deprecated
    $badParams = @(
        'AKClientSecretInsecure'
        'AliSecretInsecure'
        'AutoDNSPasswordInsecure'
        'AZPfxPass'
        'AZAppPasswordInsecure'
        'BlueCatPassword'
        'CFAuthKey'
        'CFTokenInsecure'
        'CDPasswordInsecure'
        'DSTokenInsecure'
        'DMESecretInsecure'
        'DSTokenInsecure'
        'DNSPodKeyTokenInsecure'
        'DOToken'
        'DomOffTokenInsecure'
        'DomeneshopSecretInsecure'
        'DreamhostApiKey'
        'DuckTokenInsecure'
        'DynuSecret'
        'EDKey'
        'FDPassword'
        'GandiTokenInsecure'
        'GDSecret'
        'HetznerTokenInsecure'
        'HEPassword'
        'IBMKey'
        'IBPassword'
        'InfomaniakTokenInsecure'
        'LITokenInsecure'
        'LoopiaPassInsecure'
        'LuaPassword'
        'NCApiKeyInsecure'
        'NameComToken'
        'NameSiloKeyInsecure'
        'NS1KeyInsecure'
        'OVHAppSecretInsecure'
        'OVHConsumerKeyInsecure'
        'PDKeyInsecure'
        'RSApiKeyInsecure'
        'RegRuPwdInsecure'
        'DDNSKeyValueInsecure'
        'R53SecretKeyInsecure'
        'SelectelAdminTokenInsecure'
        'SdnsPassword'
        'SimplyAPIKeyInsecure'
        'YDAdminTokenInsecure'
        'ZonomiApiKey'    
    )

    $results = foreach ($server in (Get-PAServer -List)) {
        Write-Verbose " Server: $($server.Name)"
        try { $server | Set-PAServer }
        catch {
            Write-Warning "Failed to set server $($server.Name)"
            continue 
        }

        foreach ($acct in (Get-PAAccount -List)) {
            Write-Verbose "Account: $($acct.id)"
            try { $acct | Set-PAAccount }
            catch {
                Write-Warning "Failed to set account $($acct.id)"
                continue
            }

            foreach ($order in (Get-PAOrder -List)) {
                $paNames = ($order | Get-PAPluginArgs).Keys | ForEach-Object {$_}
                if (-not $paNames) { continue }

                if ($badMatches = Compare-Object $paNames $badParams -ExcludeDifferent -IncludeEqual) {
                    [pscustomobject]@{
                        ServerName = $server.Name
                        AccountID = $acct.id
                        OrderName = $order.Name
                        Plugin = $order.Plugin
                        DeprecatedParams = $badMatches.InputObject -join ','
                    }
                }
            }
        }
    }
    $results
}
```
