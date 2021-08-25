---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/Functions/Get-PACertificate/
schema: 2.0.0
---

# Get-PACertificate

## Synopsis

Get ACME certificate details.

## Syntax

### Specific

```powershell
Get-PACertificate [[-MainDomain] <String>] [-Name <String>] [<CommonParameters>]
```

### List

```powershell
Get-PACertificate [-List] [<CommonParameters>]
```

## Description

Returns details such as Thumbprint, Subject, Validity, SANs, and file locations for one or more ACME certificates previously created.

## Examples

### Example 1

```powershell
Get-PACertificate
```

Get cached ACME order details for the currently selected order.

### Example 2

```powershell
Get-PACertificate site.example.com
```

Get cached ACME order details for the specified domain.

### Example 3

```powershell
Get-PACertificate -List
```

Get all cached ACME order details.

## Parameters

### -MainDomain
The primary domain associated with the certificate.
This is the domain that goes in the certificate's subject.

```yaml
Type: String
Parameter Sets: Specific
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
Parameter Sets: Specific
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -List
If specified, the details for all completed certificates will be returned for the current account.

```yaml
Type: SwitchParameter
Parameter Sets: List
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PoshACME.PACertificate
A certificate object.

## Related Links

[New-PACertificate](New-PACertificate.md)
