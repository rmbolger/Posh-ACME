---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAAccount/
schema: 2.0.0
---

# Get-PAAccount

## Synopsis

Get ACME account details.

## Syntax

### Specific
```powershell
Get-PAAccount [[-ID] <String>] [-Refresh] [-ExtraParams <Object>] [<CommonParameters>]
```

### List
```powershell
Get-PAAccount [-List] [-Status <String>] [-Contact <String[]>] [-KeyLength <String[]>] [-Refresh]
 [-ExtraParams <Object>] [<CommonParameters>]
```

## Description

Returns details such as Email, key length, and status for one or more ACME accounts previously created.

## Examples

### Example 1: Current Account

```powershell
Get-PAAccount
```

Get cached ACME account details for the currently selected account.

### Example 2: Specific Account

```powershell
Get-PAAccount -ID 1234567
```

Get cached ACME account details for the specified account ID.

### Example 3: All Accounts

```powershell
Get-PAAccount -List
```

Get all cached ACME account details.

### Example 4: Filter on Contact

```powershell
Get-PAAccount -List -Contact 'user1@example.com'
```

Get cached ACME account details for all accounts that have user1@example.com as the only contact.

## Parameters

### -ID
The account id value as returned by the ACME server.
'Name' is also an alias for this parameter.

```yaml
Type: String
Parameter Sets: Specific
Aliases: Name

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -List
If specified, the details for all accounts will be returned.

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

### -Status
A Status string to filter the list of accounts with.

```yaml
Type: String
Parameter Sets: List
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Contact
One or more email addresses to filter the list of accounts with.
Returned accounts must match exactly (not including the order).

```yaml
Type: String[]
Parameter Sets: List
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyLength
The type and size of private key to filter the list of accounts with.
For RSA keys, specify a number between 2048-4096 (divisible by 128).
For ECC keys, specify either 'ec-256' or 'ec-384'.

```yaml
Type: String[]
Parameter Sets: List
Aliases: AccountKeyLength

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Refresh
If specified, any account details returned will be freshly queried from the ACME server (excluding deactivated accounts).
Otherwise, cached details will be returned.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtraParams
This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

```yaml
Type: Object
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

## Outputs

### PoshACME.PAAccount
An account object.

## Related Links

[Set-PAAccount](Set-PAAccount.md)

[New-PAAccount](New-PAAccount.md)
