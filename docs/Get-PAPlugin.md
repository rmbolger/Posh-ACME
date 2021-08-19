---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Get-PAPlugin

## SYNOPSIS
Show plugin details, help, or launch the online guide.

## SYNTAX

### Basic (Default)
```
Get-PAPlugin [[-Plugin] <String>] [<CommonParameters>]
```

### Params
```
Get-PAPlugin [-Plugin] <String> [-Params] [<CommonParameters>]
```

### Guide
```
Get-PAPlugin [-Plugin] <String> [-Guide] [<CommonParameters>]
```

### Help
```
Get-PAPlugin [-Plugin] <String> [-Help] [<CommonParameters>]
```

## DESCRIPTION
With no parameters, this function will return a list of built-in validation plugins and their details.

With a Plugin specified, this function will return that plugin's details, help, or launch the online guide depending on which switches are specified.

## EXAMPLES

### EXAMPLE 1
```
Get-PAPlugin
```

Get the list of available validation plugins

### EXAMPLE 2
```
Get-PAPlugin Route53 -Guide
```

Launch the user's default web browser to the online guide for the specified plugin.

## PARAMETERS

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[New-PACertificate]()

[Publish-Challenge]()
