---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Unpublish-DnsPersistChallenge/
schema: 2.0.0
---

# Unpublish-DnsPersistChallenge

## Synopsis

Remove dns-persist-01 challenge records.

## Syntax

### FromOrder (Default)
```powershell
Unpublish-DnsPersistChallenge [-Order] <Object> [-Plugin <String[]>] [-PluginArgs <Hashtable>] [-AllowWildcard]
 [-UseAllDomains] [-PersistUntil <DateTimeOffset>] [<CommonParameters>]
```

### Standalone
```powershell
Unpublish-DnsPersistChallenge [-Domain] <String[]> [-AccountUri] <String> [-IssuerDomainName] <String>
 -Plugin <String[]> [-PluginArgs <Hashtable>] [-AllowWildcard] [-UseAllDomains]
 [-PersistUntil <DateTimeOffset>] [<CommonParameters>]
```

## Description

Removes long-lived dns-persist-01 challenge TXT record(s) for the specified order or provided set of domains. For CAs that support it, these can be used instead of more traditional dns-01 challenge records to make cert renewals easier by not requiring updated records during each renewal. Generally, they are set up in advance of a cert order so that you don't have to store your DNS API credentials on the server responsible for getting the certificate.

Unlike `Unpublish-Challenge`, this function does not require running `Save-Challenge` after use for plugins that normally require that step. The save action is run automatically at the end of this function.

## Examples

### Example 1: Remove a standalone challenge

```powershell
# Assumes the CA you're using publishes the caaIdentities field in their directory
# endpoint. If not, use the same value as the CA identifier in a CAA record.
$splat = @{
    Domain = 'example.com'
    AccountUri = (Get-PAAccount).location
    IssuerDomainName = (Get-PAServer).meta.caaIdentities[0]
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
}
Unpublish-DnsPersistChallenge @splat
```

Remove a standalone non-wildcard challenge for the current server and account.

### Example 2: Remove a wildcard challenge

```powershell
# Assumes the CA you're using publishes the caaIdentities field in their directory
# endpoint. If not, use the same value as the CA identifier in a CAA record.
$splat = @{
    Domain = 'example.com'
    AccountUri = (Get-PAAccount).location
    IssuerDomainName = (Get-PAServer).meta.caaIdentities[0]
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    AllowWildcard = $true
}
Unpublish-DnsPersistChallenge @splat
```

Remove a standalone wildcard challenge for the current server and account.

### Example 3: Remove an expiring challenge

```powershell
# Assumes the CA you're using publishes the caaIdentities field in their directory
# endpoint. If not, use the same value as the CA identifier in a CAA record.
$splat = @{
    Domain = 'example.com'
    AccountUri = (Get-PAAccount).location
    IssuerDomainName = (Get-PAServer).meta.caaIdentities[0]
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    PersistUntil = (Get-Date '2027-04-01')
}
Unpublish-DnsPersistChallenge @splat
```

Remove a standalone expiring challenge for the current server and account. 

**WARNING**: In order for `Unpublish-DnsPersistChallenge` to properly find and delete previously created expiring records, you must use the *exact* same DateTimeOffset value used with the Publish command. It is highly recommended to use specific date value you can remember such as `(Get-Date '2027-04-01')` and *not* something like `(Get-Date).AddYears(1)`.

### Example 4: Remove challenges for an order

```powershell
Get-PAOrder | Unpublish-DnsPersistChallenge
```

Removes a challenge for each domain in the current order. If you haven't configured the order with `-Plugin` and `-PluginArgs` parameters already, the Manual plugin will be used and prompt you to remove the necessary records manually.

## Parameters

### -AccountUri
The ACME account URI the record will be valid for. This can be found by running `(Get-PAAccount).location`

```yaml
Type: String
Parameter Sets: Standalone
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowWildcard
If specified, the record will have the `policy=wildcard` option added which allows validation of the domain and all nested sub-domains.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain
The domain name that the challenge will be removed for. Wildcard domains should have the "*." prefix removed.

```yaml
Type: String[]
Parameter Sets: Standalone
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -IssuerDomainName
This should generally match the CA identity value you'd normally put in a CAA record. If the CA publishes the caaIdentities field in their directory object, you can also get it using `(Get-PAServer).meta.caaIdentities[0]`. Lastly, it can be found within the actual dns-persist-01 challenge object in the `issuer-domain-names` field. 

```yaml
Type: String
Parameter Sets: Standalone
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
The PAOrder object to remove challenges for as returned by `Get-PAOrder`.

```yaml
Type: Object
Parameter Sets: FromOrder
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PersistUntil
The DateTimeOffset object for when this records validation will expire.

**WARNING**: In order for `Unpublish-DnsPersistChallenge` to properly find and delete previously created expiring records, you must use the *exact* same DateTimeOffset value used with the Publish command. It is highly recommended to use specific date value you can remember such as `(Get-Date '2027-04-01')` and *not* something like `(Get-Date).AddYears(1)`.

```yaml
Type: DateTimeOffset
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Plugin
The name of the validation plugin to use.
Use Get-PAPlugin to display a list of available plugins.

```yaml
Type: String[]
Parameter Sets: FromOrder
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String[]
Parameter Sets: Standalone
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginArgs
A hashtable containing the plugin arguments to use with the specified plugin.
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as `@{MyText='text';MyNumber=1234}`.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAllDomains
When used with `-AllowWildcard`, this switch ensures a record will be created for all domains in the list or order. Otherwise, a record will only be created for the most generic set of domains that will match all domains in the list.

For example, if the list contains `example.com`, `sub1.example.com`, and `example.net`, `-AllowWildcard` will skip creating the record for `sub1.example.com` because it is already covered by the record created for `example.com`. But with `-UseAllDomains`, the `sub1.example.com` record will be created as well.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Publish-DnsPersistChallenge](Publish-DnsPersistChallenge.md)

[Get-PAPlugin](Get-PAPlugin.md)
