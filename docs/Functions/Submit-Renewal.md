---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Submit-Renewal/
schema: 2.0.0
---

# Submit-Renewal

## Synopsis

Renew one or more certificates.

## Syntax

### Specific

```powershell
Submit-Renewal [[-MainDomain] <String>] [[-Name] <String>] [-Force] [-NoSkipManualDns]
 [-PluginArgs <Hashtable>] [<CommonParameters>]
```

### AllOrders

```powershell
Submit-Renewal [-AllOrders] [-Force] [-NoSkipManualDns] [-PluginArgs <Hashtable>] [<CommonParameters>]
```

### AllAccounts

```powershell
Submit-Renewal [-AllAccounts] [-Force] [-NoSkipManualDns] [-PluginArgs <Hashtable>] [<CommonParameters>]
```

## Description

Technically, a renewal is just a normal new certificate order using the same parameters as a previous order. This function allows you to easily request a new certificate for any existing order

This function allows you to renew one more more previously complete orders as long as the renewal window has been reached and plugin configuration exists to automate the challenge validation. It will also pick up and attempt to continue pending or previously failed orders. You can choose to renew a specific order, set of orders, all orders for the current account, or all orders for all accounts.

A PACertificate object is returned for every successfully renewed order.

## Examples

### Example 1: Renew Current

```powershell
Submit-Renewal
```

Renew the current order on the current account.

### Example 2: Force Specific Order

```powershell
Submit-Renewal example.com -Force
```

Renew the specified order on the current account even if it hasn't reached its suggested renewal window.

### Example 3: All Orders

```powershell
Submit-Renewal -AllOrders
```

Renew all valid orders on the current account that have reached their suggested renewal window.

### Example 4: All Orders on All Accounts

```powershell
Submit-Renewal -AllAccounts
```

Renew all valid orders on all valid accounts that have reached their suggested renewal window.

### Example 5: Update PluginArgs

```powershell
$pArgs = @{ (Read-Host 'FakeDNS API Token' -AsSecureString) }
Submit-Renewal -PluginArgs $pArgs
```

Renew the current order using updated plugin args that will also be saved for subsequent renewals.

## Parameters

### -MainDomain
The primary domain associated with an order.
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
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AllOrders
If specified, renew all valid orders on the current account.
Orders that have not reached the renewal window will be skipped unless -Force is used.

```yaml
Type: SwitchParameter
Parameter Sets: AllOrders
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllAccounts
If specified, renew all valid orders on all valid accounts in this profile.
Orders that have not reached the renewal window will be skipped unless -Force is used.

```yaml
Type: SwitchParameter
Parameter Sets: AllAccounts
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, an order that hasn't reached its renewal window will not throw an error and will not be skipped when using either of the -All parameters.

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

### -NoSkipManualDns
If specified, orders that utilize the Manual DNS plugin will not be skipped and user interaction may be required to complete the process.
Otherwise, orders that utilize the Manual DNS plugin will be skipped.

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

### -PluginArgs
A hashtable containing an updated set of plugin arguments to use with the renewal.
So if a plugin has a `MyText` string and `MyNumber` integer parameter, you could specify them as `@{MyText='text';MyNumber=1234}`.

```yaml
Type: Hashtable
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

### PoshACME.PACertificate
A certificate object.

## NOTES

Certificate objects are only returned for orders that were actually renewed successfully. Any orders that have not reached the suggested renewal window are skipped unless `-Force` is specified.

## Related Links

[New-PACertificate](New-PACertificate.md)

[Get-PAOrder](Get-PAOrder.md)
