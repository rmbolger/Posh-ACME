---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/New-PAAuthorization/
schema: 2.0.0
---

# New-PAAuthorization

## Synopsis

Create a pre-authorization for an ACME identifier.

## Syntax

```powershell
New-PAAuthorization [-Domain] <String[]> [[-Account] <Object>] [<CommonParameters>]
```

## Description

Instead of creating an ACME order object and satisfying the associated authorization challenges on demand, users may choose to pre-authorize one or more identifiers in advance.
When a user later creates an order with pre-authorized identifiers, it will be immediately ready to finalize.

NOTE: Not all ACME servers support pre-authorization.
The authorizations created this way also expire the same way they do when associated directly with an order.

## Examples

### Example 1

```powershell
$auth = New-PAAuthorization example.com
```

Create a new authorization for the specified domain using the current account.

### Example 2

```powershell
$auths = 'example.com','www.example.com' | New-PAAuthorization -Account (Get-PAAccount 123)
```

Create new authorizations for the specified domains via the pipeline and using the specified account.

## Parameters

### -Domain
One or more ACME identifiers (usually domain names).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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
The domain or IP address identifier to authorize.

## Outputs

### PoshACME.PAAuthorization
An authorization object.

## Related Links

[Get-PAAuthorization](Get-PAAuthorization.md)

[New-PAOrder](New-PAOrder.md)
