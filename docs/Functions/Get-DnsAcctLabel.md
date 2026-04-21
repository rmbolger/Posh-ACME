---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-DnsAcctLabel/
schema: 2.0.0
---

# Get-DnsAcctLabel

## Synopsis

Calculate the `dns-account-01` FQDN label for the specified account URI.

## Syntax

```powershell
Get-DnsAcctLabel [-AccountUri] <String> [<CommonParameters>]
```

## Description

Use this if you need to pre-create a CNAME delegation for a `dns-account-01` challenge or otherwise know in advance what the account specific FQDN will be.

## Examples

### Example 1:

```powershell
Get-PAAccount | Get-DnsAcctLabel
```

Get the label for the current account.

## Parameters

### -AccountUri
An ACME account URI value which can be found in the `location` field of `Get-PAAccount` output.

```yaml
Type: String
Parameter Sets: (All)
Aliases: location

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

### System.String
An ACME account URI value.

## Outputs

### System.String
The DNS label.

## Related Links

[Publish-Challenge](Publish-Challenge.md)
