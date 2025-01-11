---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAProfile/
schema: 2.0.0
---

# Get-PAProfile

## Synopsis

Get current CA supported certificate/order profiles.

## Syntax

```powershell
Get-PAProfile [[-Profile] <String>] [<CommonParameters>]
```

## Description

ACME CAs that implement the ACME profiles extension allow for subscribers to choose from a list of supported certificate profiles when creating a new order. This function returns the currently supported profile details for the current ACME CA. The Profile name is used with the `-Profile` parameter in functions like `New-PACertificate`.

## Examples

### Example 1: All Profiles

```powershell
Get-PAProfile
```

Get all supported ACME profiles on the current server.

### Example 2: Specific Profile

```powershell
Get-PAProfile -Profile tlsserver
```

Get a specific ACME profile on the current server.

## Parameters

### -Profile
The name of the desired ACME certificate profile. Returns nothing if the profile doesn't exist on this CA.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PoshACME.PAProfile
An profile object.

## Related Links

[New-PAOrder](New-PAOrder.md)

[New-PACertificate](New-PACertificate.md)
