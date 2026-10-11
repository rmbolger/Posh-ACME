---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Publish-DnsPersistChallenge/
schema: 2.0.0
---

# Publish-DnsPersistChallenge

## Synopsis

Publish dns-persist-01 challenge records.

## Syntax

### PreProvision (Default)
```powershell
Publish-DnsPersistChallenge [-Domain] <String[]> -Account <Object> [-AccountHashPrefix <String>]
 [-IssuerDomainName <String>] [-Plugin <String[]>] [-PluginArgs <Hashtable>] [-AllowWildcard]
 [-PersistUntil <DateTimeOffset>] [-NoAutoWildcard] [-NoDomainCorrelationMitigation] [<CommonParameters>]
```

### FromOrder
```powershell
Publish-DnsPersistChallenge [-Order] <Object> [-AccountHashPrefix <String>] [-IssuerDomainName <String>]
 [-Plugin <String[]>] [-PluginArgs <Hashtable>] [-AllowWildcard] [-PersistUntil <DateTimeOffset>]
 [-NoAutoWildcard] [-NoDomainCorrelationMitigation] [<CommonParameters>]
```

### Advanced
```powershell
Publish-DnsPersistChallenge [-Domain] <String[]> -HashedAccountUri <String> [-IssuerDomainName <String>]
 [-Plugin <String[]>] [-PluginArgs <Hashtable>] [-AllowWildcard] [-PersistUntil <DateTimeOffset>]
 [-NoAutoWildcard] [<CommonParameters>]
```

### PreProvisionExplicit
```powershell
Publish-DnsPersistChallenge [-Domain] <String[]> -AccountUri <String> -KeyThumbprint <String>
 [-AccountHashPrefix <String>] [-IssuerDomainName <String>] [-Plugin <String[]>] [-PluginArgs <Hashtable>]
 [-AllowWildcard] [-PersistUntil <DateTimeOffset>] [-NoAutoWildcard] [-NoDomainCorrelationMitigation]
 [<CommonParameters>]
```

## Description

Publishes long-lived dns-persist-01 challenge TXT record(s) for the specified order or provided set of domains. For CAs that support it, these can be used instead of more traditional dns-01 challenge records to make cert renewals easier by not requiring updated records during each renewal. Generally, they are set up in advance of a cert order so that you don't have to store your DNS API credentials on the server responsible for getting the certificate.

Unlike [Publish-Challenge](Publish-Challenge.md), this function does not require running [Save-Challenge](Save-Challenge.md) after use for plugins that normally require that step. The save action is run automatically at the end of this function.

## Examples

### Example 1: Pre-Provision a standalone challenge

```powershell
$pubParams = @{
    Domain = 'example.com'
    Account = (Get-PAAccount)
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
}
Publish-DnsPersistChallenge @pubParams
```

Publish a standalone non-wildcard challenge for the current server and account.

### Example 2: Pre-Provision a wildcard challenge

```powershell
$pubParams = @{
    Domain = '*.example.com'
    Account = (Get-PAAccount)
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
}
Publish-DnsPersistChallenge @pubParams
```

Publish a standalone wildcard challenge for the current server and account. The `policy=wildcard` flag is automatically added to the record due to the "*." prefix and will work for the specified domain and any subdomains including nested subdomains.

### Example 3: Pre-Provision an expiring challenge

```powershell
$pubParams = @{
    Domain = 'example.com'
    Account = (Get-PAAccount)
    Plugin = 'FakeDNS'
    PluginArgs = @{
        FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    }
    PersistUntil = '2027-04-01Z'
}
Publish-DnsPersistChallenge @pubParams
```

Publish a standalone expiring challenge for the current server and account.

**WARNING**: In order for `Unpublish-DnsPersistChallenge` to properly find and delete previously created expiring records, you must use the *exact* same DateTimeOffset value and timezone used with the Publish command. It is highly recommended to use a UTC date-only value you can remember such as `'2027-04-01Z'` and *not* something relative to "now" like `[DateTimeOffset]::Now.AddYears(1)`.

### Example 4: Publish challenges for an order

```powershell
Get-PAOrder | Publish-DnsPersistChallenge
```

Publishes a challenge for each domain in the current order. If you haven't configured the order with `-Plugin` and `-PluginArgs` parameters already, the Manual plugin will be used and prompt you to create the necessary records manually.

## Parameters

### -Account
The ACME account associated with the challenge.

```yaml
Type: Object
Parameter Sets: PreProvision
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccountUri
The account URI for the ACME account the persist record is being published for. This should be retrievable using `(Get-PAAccount).location` or provided by the account owner.

```yaml
Type: String
Parameter Sets: PreProvisionExplicit
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowWildcard
If specified, the record will have the `policy=wildcard` option added which allows validation of the domain and all nested sub-domains.

```yaml
Type: SwitchParameter
Parameter Sets: PreProvision, FromOrder, PreProvisionExplicit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: Advanced
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain
The domain name(s) that the challenge record will be published for. Wildcard prefixed names such as `*.example.com` are allowed and will have the `policy=wildcard` field added automatically unless `-NoAutoWildcard` is specified.

```yaml
Type: String[]
Parameter Sets: PreProvision, PreProvisionExplicit
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

```yaml
Type: String[]
Parameter Sets: Advanced
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -HashedAccountUri
The hashed account URI identifying the ACME account requesting validation which cryptographically binds the account key to the validation domain. This is the `HashedAccountUri` property returned by [Get-DnsPersistAccountUri](Get-DnsPersistAccountUri.md), which can be piped in with its matching `Domain` property.

```yaml
Type: String
Parameter Sets: Advanced
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -IssuerDomainName
Any of the values published by the CA in the `issuerDomainNames` array in the meta object of its directory. You should be able to query one using `(Get-PAServer).meta.issuerDomainNames[0]`. Challenge objects for `dns-persist-01` must also have this list in a `issuerDomainNames` field. They generally also correspond to the CA identity value you'd normally put in a CAA record.

```yaml
Type: String
Parameter Sets: PreProvision, FromOrder, PreProvisionExplicit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Advanced
Aliases:

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
Parameter Sets: PreProvisionExplicit
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
The PAOrder object to publish challenges for as returned by `Get-PAOrder`.

```yaml
Type: Object
Parameter Sets: FromOrder
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PersistUntil
A DateTimeOffset object for when this record's validation will expire. Can be passed as a locale-dependent parseable string.

**WARNING**: In order for `Unpublish-DnsPersistChallenge` to properly find and delete previously created expiring records, you must use the *exact* same DateTimeOffset value and timezone used with the Publish command. It is highly recommended to use a UTC date-only value you can remember such as `'2027-04-01Z'` and *not* something relative to "now" like `[DateTimeOffset]::Now.AddYears(1)`.

```yaml
Type: DateTimeOffset
Parameter Sets: PreProvision, FromOrder, PreProvisionExplicit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: DateTimeOffset
Parameter Sets: Advanced
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Plugin
The name of the validation plugin to use.
Use Get-PAPlugin to display a list of available plugins.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginArgs
A hashtable containing the plugin arguments to use with the specified plugin.
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as `@{MyText='text';MyNumber=1234}`.

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

### -AccountHashPrefix
The accountHashPrefix value that the CA must publish in the meta object of its directory. This should be retrievable using `(Get-PAServer).meta.accountHashPrefix`.

```yaml
Type: String
Parameter Sets: PreProvision, FromOrder, PreProvisionExplicit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoAutoWildcard
When specified, stops the function from automatically adding the `policy=wildcard` parameter to TXT records associated with wildcard domains such as `*.example.com`. If your order or list of domains has a wildcard and this switch is used, the domain will be skipped and an associated warning will be thrown. This switch is ignored when also using `-AllowWildcard`.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDomainCorrelationMitigation
By default, the `accountUri` field in the TXT record value for `_validation-persist` records is partially based on the domain name the record is authorizing. This is to prevent observers of the record data from correlating that a set of domains are associated with the same ACME account. When specified, this switch opts out of the domain correlation mitigation by using `*` as the domain name in the hashed value instead of the actual domain name. This effectively makes the `accountUri` field the same for all records being authorized from the same ACME account. Some users may prefer this operational simplicity in favor of the privacy benefits of the default.

```yaml
Type: SwitchParameter
Parameter Sets: PreProvision, FromOrder, PreProvisionExplicit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Unpublish-DnsPersistChallenge](Unpublish-DnsPersistChallenge.md)

[Get-DnsPersistAccountUri](Get-DnsPersistAccountUri.md)
