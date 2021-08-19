---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Install-PACertificate

## SYNOPSIS
Install a Posh-ACME certificate into a Windows certificate store.

## SYNTAX

```
Install-PACertificate [[-PACertificate] <Object>] [[-StoreLocation] <String>] [[-StoreName] <String>]
 [-NotExportable] [<CommonParameters>]
```

## DESCRIPTION
This can be used instead of the -Install parameter on New-PACertificate to import a certificate with more configurable options.

## EXAMPLES

### EXAMPLE 1
```
Install-PACertificate
```

Install the certificate for the currently selected order to the default LocalMachine\My store.

### EXAMPLE 2
```
Get-PACertificate example.com | Install-PACertificate
```

Install the specified certificate to the default LocalMachine\My store.

### EXAMPLE 3
```
Install-PACertificate -StoreLocation 'CurrentUser' -NotExportable
```

Install the certificate for the currently selected order to the CurrentUser\My store and mark the private key as not exportable.

## PARAMETERS

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PACertificate]()
