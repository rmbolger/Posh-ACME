---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# New-PAAccount

## SYNOPSIS
Create a new account on the current ACME server.

## SYNTAX

### Generate (Default)
```
New-PAAccount [[-Contact] <String[]>] [[-KeyLength] <String>] [-ID <String>] [-AcceptTOS] [-Force]
 [-ExtAcctKID <String>] [-ExtAcctHMACKey <String>] [-ExtAcctAlgorithm <String>] [-UseAltPluginEncryption]
 [-ExtraParams <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ImportKey
```
New-PAAccount [[-Contact] <String[]>] -KeyFile <String> [-ID <String>] [-AcceptTOS] [-OnlyReturnExisting]
 [-Force] [-ExtAcctKID <String>] [-ExtAcctHMACKey <String>] [-ExtAcctAlgorithm <String>]
 [-UseAltPluginEncryption] [-ExtraParams <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
All certificate requests require a valid account on an ACME server.
Adding an email contact is not required.
But without one, certificate expiration notices will not be sent.
The account KeyLength is personal preference and doesn't correspond to the KeyLength of the generated certificates.

## EXAMPLES

### EXAMPLE 1
```
New-PAAccount -AcceptTOS
```

Create a new account with no contact email and the default key length.

### EXAMPLE 2
```
New-PAAccount -Contact user1@example.com -AcceptTOS
```

Create a new account with the specified email and the default key length.

### EXAMPLE 3
```
New-PAAccount -Contact user1@example.com -KeyLength 4096 -AcceptTOS
```

Create a new account with the specified email and an RSA 4096 bit key.

### EXAMPLE 4
```
New-PAAccount -KeyLength 'ec-384' -AcceptTOS -Force
```

Create a new account with no contact email and an ECC key using P-384 curve that ignores any confirmations.

### EXAMPLE 5
```
New-PAAccount -KeyFile .\mykey.key -AcceptTOS
```

Create a new account using a pre-generated private key file.

## PARAMETERS

### -Contact
One or more email addresses to associate with this account.
These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyLength
The type and size of private key to use.
For RSA keys, specify a number between 2048-4096 (divisible by 128).
For ECC keys, specify either 'ec-256' or 'ec-384'.
Defaults to 'ec-256'.

```yaml
Type: String
Parameter Sets: Generate
Aliases: AccountKeyLength

Required: False
Position: 2
Default value: Ec-256
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyFile
The path to an existing EC or RSA private key file.
This will attempt to create the account using the specified key as the ACME account key.
This can be used to recover/import an existing ACME account if one is already associated with the key.

```yaml
Type: String
Parameter Sets: ImportKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ID
The name of the ACME acccount.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AcceptTOS
If not specified, the ACME server will throw an error with a link to the current Terms of Service.
Using this switch indicates acceptance of those Terms of Service and is required for successful account creation.

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

### -OnlyReturnExisting
If specified, the ACME server will only return the account details if they already exist for the given private key. Otherwise, an error will be thrown. This can be useful to check whether an existing private key is associated with an ACME acount and recover the account details without creating a new account.

```yaml
Type: SwitchParameter
Parameter Sets: ImportKey
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, confirmation prompts that may have been generated will be skipped.

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

### -ExtAcctKID
The external account key identifier supplied by the CA.
This is required for ACME CAs that require external account binding.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtAcctHMACKey
The external account HMAC key supplied by the CA and encoded as Base64Url.
This is required for ACME CAs that require external account binding.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtAcctAlgorithm
The HMAC algorithm to use.
Defaults to 'HS256'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: HS256
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAltPluginEncryption
If specified, the account will be configured to use a randomly generated AES key to encrypt sensitive plugin parameters on disk instead of using the OS's native encryption methods.
This can be useful if the config is being shared across systems or platforms.
You can revert to OS native encryption using -UseAltPluginEncryption:$false.

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

## INPUTS

## OUTPUTS

### PoshACME.PAAccount
## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PAAccount]()

[Set-PAAccount]()
