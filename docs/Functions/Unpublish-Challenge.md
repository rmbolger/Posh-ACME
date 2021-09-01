---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Unpublish-Challenge/
schema: 2.0.0
---

# Unpublish-Challenge

## Synopsis

Unpublish a challenge using the specified plugin.

## Syntax

```powershell
Unpublish-Challenge [-Domain] <String> [-Account] <Object> [-Token] <String> [-Plugin] <String>
 [[-PluginArgs] <Hashtable>] [-DnsAlias <String>] [<CommonParameters>]
```

## Description

Based on the type of validation plugin specified, this function will unpublish either a DNS TXT record or an HTTP challenge file for the given domain and token value that satisfies the dns-01 or http-01 challenge specification.

Depending on the plugin, calling `Save-Challenge` may be required to commit changes made by `Unpublish-Challenge`.
If multiple challenges are being unpublished, make all `Unpublish-Challenge` calls first.
Then, `Save-Challenge` once to commit them all.

## Examples

### Example 1

```powershell
$auths = Get-PAOrder | Get-PAAuthorization
Unpublish-Challenge $auths[0].DNSId (Get-PAAccount) $auths[0].DNS01Token Manual @{}
```

Unpublish a DNS challenge for the first authorization in the current order using the Manual DNS plugin.

### Example 2

```powershell
$pArgs = @{Param1='asdf';Param2=1234}
$acct = Get-PAAccount
Unpublish-Challenge example.com $acct MyPlugin $pArgs -Token faketoken
```

Unpublish a challenge for example.com using a fictitious plugin and arguments.

## Parameters

### -Domain
The domain name that the challenge will be unpublished for.
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
The account object associated with the order that required the challenge.

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
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

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
When using DNS Alias support with DNS validation plugins, the alias domain that the TXT record will be removed from.
This should be the complete FQDN including the '_acme-challenge.' prefix if necessary.
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

[Publish-Challenge](Publish-Challenge.md)

[Save-Challenge](Save-Challenge.md)

[Get-PAPlugin](Get-PAPlugin.md)
