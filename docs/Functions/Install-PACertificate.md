---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Install-PACertificate/
schema: 2.0.0
---

# Install-PACertificate

## Synopsis

Install a Posh-ACME certificate into a Windows certificate store.

## Syntax

```powershell
Install-PACertificate [[-PACertificate] <Object>] [[-StoreLocation] <String>] [[-StoreName] <String>]
 [-NotExportable] [<CommonParameters>]
```

## Description

This can be used instead of the `-Install` parameter on `New-PACertificate` to import a certificate with additional options.

## Examples

### Example 1: Import Current Certificate

```powershell
Install-PACertificate
```

Install the certificate for the currently selected order to the default LocalMachine\My store.

### Example 2: Import Specific Certificate

```powershell
Get-PACertificate example.com | Install-PACertificate
```

Install the specified certificate to the default LocalMachine\My store.

### Example 3: Import with Options

```powershell
Install-PACertificate -StoreLocation 'CurrentUser' -NotExportable
```

Install the certificate for the currently selected order to the CurrentUser\My store and mark the private key as not exportable.

## Parameters

### -PACertificate
The PACertificate object you want to import.
This can be retrieved using Get-PACertificate and is also returned from things like New-PACertificate and Submit-Renewal.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -StoreLocation
Either 'LocalMachine' or 'CurrentUser'.
Defaults to 'LocalMachine'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: LocalMachine
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoreName
The name of the certificate store to import to.
Defaults to 'My'.
The store must already exist and will not be created automatically.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: My
Accept pipeline input: False
Accept wildcard characters: False
```

### -NotExportable
If specified, the private key will not be marked as Exportable.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

### PoshACME.PACertificate
A certificate object as returned by Get-PACertificate.

## Notes

This function only currently works on Windows OSes. A warning will be thrown on other OSes.

## Related Links

[Get-PACertificate](Get-PACertificate.md)
