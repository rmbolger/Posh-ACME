---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Save-Challenge/
schema: 2.0.0
---

# Save-Challenge

## Synopsis

Commit changes made by Publish-Challenge or Unpublish-Challenge.

## Syntax

```powershell
Save-Challenge [-Plugin] <String> [[-PluginArgs] <Hashtable>] [<CommonParameters>]
```

## Description

Some validation plugins require a finalization step after the Publish or Unpublish functionality to commit and make the changes live. This function should be called once after running all of the `Publish-Challenge` or `Unpublish-Challenge` commands.

For plugins that don't require a commit step, this function may still be run without causing an error, but has no effect.

## Examples

### Example 1: Commit Changes

```powershell
$pArgs = @{ FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString) }
Save-Challenge -Plugin FakeDNS -PluginArgs $pArgs
```

Commit changes that the specified plugin has made.

## Parameters

### -Plugin
The name of the validation plugin to use.
Use Get-PAPlugin to display a list of available plugins.

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

### -PluginArgs
A hashtable containing the plugin arguments to use with the specified plugin.
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as `@{MyText='text';MyNumber=1234}`.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Publish-Challenge](Publish-Challenge.md)

[Unpublish-Challenge](Unpublish-Challenge.md)

[Get-PAPlugin](Get-PAPlugin.md)
