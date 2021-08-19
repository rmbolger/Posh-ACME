---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Get-PAPluginArgs

## SYNOPSIS
Retrieve the plugin args for the current or specified order.

## SYNTAX

```
Get-PAPluginArgs [[-MainDomain] <String>] [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
An easy way to recall the plugin args used for a given order.

## EXAMPLES

### EXAMPLE 1
```
Get-PAPluginArgs
```

Retrieve the plugin args for the current order.

### EXAMPLE 2
```
Get-PAPluginArgs -Name myorder
```

Retrieve the plugin args for the specified order.

### EXAMPLE 3
```
Get-PAOrder -Name myorder | Get-PAPluginArgs
```

Retrieve the plugin args for the order passed via the pipeline.

## PARAMETERS

### -MainDomain
The primary domain for the order.
For a SAN order, this was the first domain in the list when creating the order.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
The name of the ACME order.
This can be useful to distinguish between two orders that have the same MainDomain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Collections.Hashtable
## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Gew-PAOrder]()
