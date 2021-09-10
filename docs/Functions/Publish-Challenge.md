---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Publish-Challenge/
schema: 2.0.0
---

# Publish-Challenge

## Synopsis

Publish a challenge using the specified plugin.

## Syntax

```powershell
Publish-Challenge [-Domain] <String> [-Account] <Object> [-Token] <String> [-Plugin] <String>
 [[-PluginArgs] <Hashtable>] [-DnsAlias <String>] [<CommonParameters>]
```

## Description

Based on the type of validation plugin specified, this function will publish either a DNS TXT record or an HTTP challenge file for the given domain and token value that satisfies the dns-01 or http-01 challenge specification.

Depending on the plugin, calling `Save-Challenge` may be required to commit changes made by `Publish-Challenge`.
If multiple challenges are being published, make all `Publish-Challenge` calls first.
Then, `Save-Challenge` once to commit them all.

## Examples

### Example 1: Publish a Challenge

```powershell
$splat = @{
    Domain = 'example.com'
    Account = (Get-PAAccount)
    Token = 'fake-token'
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
}
Publish-Challenge @splat

# if plugin requires saving
Save-Challenge -Plugin $splat.Plugin -PluginArgs $splat.PluginArgs
```

Publish a single DNS challenge.

### Example 2: DNS Order Challenges

```powershell
$splat = @{
    Account = (Get-PAAccount)
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
}
Get-PAOrder | Get-PAAuthorization | ForEach-Object {
    Publish-Challenge -Domain $_.DNSId -Token $_.DNS01Token @splat
}

# if plugin requires saving
Save-Challenge -Plugin $splat.Plugin -PluginArgs $splat.PluginArgs
```

Publish DNS challenges for all authorizations in the current order.

### Example 3: HTTP Order Challenges

```powershell
$splat = @{
    Account = (Get-PAAccount)
    Plugin = 'WebSelfHost'
    PluginArgs = @{}
}
Get-PAOrder | Get-PAAuthorization | ForEach-Object {
    Publish-Challenge -Domain $_.DNSId -Token $_.HTTP01Token @splat
}

# if plugin requires saving
Save-Challenge -Plugin $splat.Plugin -PluginArgs $splat.PluginArgs
```

Publish HTTP challenges for all authorizations in the current order.

## Parameters

### -Domain
The domain name that the challenge will be published for.
Wildcard domains should have the "*." removed and can only be used with DNS based validation plugins.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Account
The account object associated with the order that requires the challenge.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Token
The token value from the appropriate challenge in an authorization object that matches the plugin type.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Plugin
The name of the validation plugin to use.
Use Get-PAPlugin to display a list of available plugins.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsAlias
When using DNS Alias support with DNS validation plugins, the alias domain that the TXT record will be written to.
This should be the complete FQDN including the `_acme-challenge.` prefix if necessary.
This field is ignored for non-DNS validation plugins.

```yaml
Type: String
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

[Unpublish-Challenge](Unpublish-Challenge.md)

[Save-Challenge](Save-Challenge.md)

[Get-PAPlugin](Get-PAPlugin.md)
