---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Export-PAAccountKey/
schema: 2.0.0
---

# Export-PAAccountKey

## Synopsis

Export an ACME account private key.

## Syntax

```powershell
Export-PAAccountKey [[-ID] <String>] -OutputFile <String> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

The account key is saved as an unencrypted Base64 encoded PEM file.

## Examples

### Example 1: Export the current account key

```powershell
Export-PAAccountKey -OutputFile .\mykey.pem
```

Exports the current ACME account's key to the specified file.

### Example 2: Export the specified account key

```powershell
Export-PAAccountKey 12345 -OutputFile .\mykey.pem -Force
```

Exports the specified ACME account's key to the specified file and overwrites it if necessary.

### Example 3: Backup account keys to the desktop

```powershell
$fldr = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AcmeAccountKeys'
New-Item -ItemType Directory -Force -Path $fldr | Out-Null
Get-PAAccount -List | %{
    Export-PAAccountKey $_.ID -OutputFile "$fldr\$($_.ID).key" -Force
}
```

Backup all account keys for this ACME server to a folder on the desktop.

## Parameters

### -ID
The ACME account ID value.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFile
The path to the file to write the key data to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified and the output file already exists, it will be overwritten.
Without the switch, a confirmation prompt will be presented.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Get-PAAccount](Get-PAAccount.md)
