---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-DnsPersistAccountUri/
schema: 2.0.0
---

# Get-DnsPersistAccountUri

## Synopsis

Calculate the hashed URI required for the accountUri field in a dns-persist-01 validation record.

## Syntax

### NativeAccount (Default)
```powershell
Get-DnsPersistAccountUri [-Domain] <String> [[-Account] <Object>] [-AccountHashPrefix <String>]
 [-HashAlgorithm <String>] [<CommonParameters>]
```

### ExplicitAccountDetails
```powershell
Get-DnsPersistAccountUri [-Domain] <String> [-AccountUri] <String> [-KeyThumbprint] <String>
 [-AccountHashPrefix <String>] [-HashAlgorithm <String>] [<CommonParameters>]
```

## Description

The _validation-persist TXT record required to satisfy dns-persist-01 challenges requires an accountUri parameter whose value is a hashed URI identifying the ACME account requesting validation. The hashed URI cryptographically binds the account to the domain being validated without publishing the account URL in cleartext.

## Examples

### Example 1: Current account and CA published accountHashPrefix

```powershell
Get-DnsPersistAccountUri 'example.com'
```

Get the accountUri value using the current ACME account and the accountHashPrefix value that must be published by the CA.

### Example 2: Current account and overridden accountHashPrefix

```powershell
Get-DnsPersistAccountUri 'example.com' -AccountHashPrefix 'https://ca.example/account-hash/'
```

Get the accountUri value using the current ACME account and the specified accountHashPrefix.

### Example 3: Explicit account Uri and thumbprint

```powershell
Get-DnsPersistAccountUri 'example.com' -AccountUri 'https://ca.example/acct/123' -KeyThumbprint 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs'
```

Get the accountUri value using explicit AccountUri and Thumbprint values. This is mostly useful for testing or if you don't have local access to the account private key.

## Parameters

### -Account
The ACME account associated with the challenge.

```yaml
Type: Object
Parameter Sets: NativeAccount
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccountHashPrefix
The accountHashPrefix value that the CA must publish in the meta object of its directory. This should be retrievable using `(Get-PAServer).meta.accountHashPrefix`.

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

### -AccountUri
The account URI for the ACME account the persist record is being published for. This should be retrievable using `(Get-PAAccount).location` or provided by the account owner.

```yaml
Type: String
Parameter Sets: ExplicitAccountDetails
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain
The domain FQDN name that the challenge record will be published for. Do not include wildcard `*.` or `_validation-persist.` prefixes. But you may set the domain to `*` to opt-out of the default domain correlation privacy protections in the resulting value. See the `-NoDomainCorrelationMitigation` switch in [Publish-DnsPersistChallenge](Publish-DnsPersistChallenge.md) for more details.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -HashAlgorithm
The RFC6920 hash algorithm used to hash the necessary data. The only currently supported algorithm is 'sha-256' which is the default. Additional algorithms may be supported in the future but will also require explicit CA support.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: sha-256

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyThumbprint
The ACME account key JWK thumbprint as calculated by RFC7638.


```yaml
Type: String
Parameter Sets: ExplicitAccountDetails
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### System.String
The accountUri value for the _validation-persist TXT record.

## Related Links

[Publish-DnsPersistChallenge](Publish-DnsPersistChallenge.md)

[Unpublish-DnsPersistChallenge](Unpublish-DnsPersistChallenge.md)
