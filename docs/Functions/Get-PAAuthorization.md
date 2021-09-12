---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAAuthorization/
schema: 2.0.0
---

# Get-PAAuthorization

## Synopsis

Get the authorizations associated with a particular order or set of authorization URLs.

## Syntax

```powershell
Get-PAAuthorization [-AuthURLs] <String[]> [[-Account] <Object>] [<CommonParameters>]
```

## Description

Returns details such as fqdn, status, expiration, and challenges for one or more ACME authorizations.

## Examples

### Example 1: Specific Authorization

```powershell
Get-PAAuthorization https://acme.example.com/authz/1234567
```

Get the authorization for the specified URL.

### Example 2: Order Authorizations

```powershell
Get-PAOrder | Get-PAAuthorization
```

Get the authorizations for the current order on the current account.

## Parameters

### -AuthURLs
One or more authorization URLs.
You also pipe in one or more PoshACME.PAOrder objects.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: authorizations

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Account
An existing ACME account object such as the output from Get-PAAccount.
If no account is specified, the current account will be used.

```yaml
Type: Object
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

## Inputs

### System.String
The URI of the authorization object.

## Outputs

### PoshACME.PAAuthorization
An authorization object.

## Related Links

[Get-PAOrder](Get-PAOrder.md)

[New-PAOrder](New-PAOrder.md)
