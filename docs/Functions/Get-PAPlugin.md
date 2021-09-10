---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAPlugin/
schema: 2.0.0
---

# Get-PAPlugin

## Synopsis

Show plugin details, help, or launch the online guide.

## Syntax

### Basic (Default)

```powershell
Get-PAPlugin [[-Plugin] <String>] [<CommonParameters>]
```

### Params

```powershell
Get-PAPlugin [-Plugin] <String> [-Params] [<CommonParameters>]
```

### Guide

```powershell
Get-PAPlugin [-Plugin] <String> [-Guide] [<CommonParameters>]
```

### Help

```powershell
Get-PAPlugin [-Plugin] <String> [-Help] [<CommonParameters>]
```

## Description

With no parameters, this function will return a list of built-in validation plugins and their details.

With a Plugin specified, this function will return that plugin's details, help, or launch the online guide depending on which switches are specified.

## Examples

### Example 1: List Plugins

```powershell
Get-PAPlugin
```

Get the list of available validation plugins

### Example 2: Show Plugin Parameter Sets

```powershell
Get-PAPlugin Route53 -Params
```

Launch the user's default web browser to the online guide for the specified plugin.

### Example 3: Open Plugin Guide

```powershell
Get-PAPlugin Route53 -Guide
```

Launch the user's default web browser to the online guide for the specified plugin.

## Parameters

### -Plugin
The name of a validation plugin.

```yaml
Type: String
Parameter Sets: Basic
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Params, Guide, Help
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Help
If specified, display the help contents for the specified plugin.

```yaml
Type: SwitchParameter
Parameter Sets: Help
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Guide
If specified, launch the default web browser to the specified plugin's online guide.
This currently only works on Windows and will simply display the URL on other OSes.

```yaml
Type: SwitchParameter
Parameter Sets: Guide
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Params
If specified, returns the plugin-specific parameter sets associated with this plugin.

```yaml
Type: SwitchParameter
Parameter Sets: Params
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[New-PACertificate](New-PACertificate.md)

[Publish-Challenge](Publish-Challenge.md)
