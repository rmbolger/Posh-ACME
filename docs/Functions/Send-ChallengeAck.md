---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Send-ChallengeAck/
schema: 2.0.0
---

# Send-ChallengeAck

## Synopsis

Notify the ACME server to try validating a challenge.

## Syntax

```powershell
Send-ChallengeAck [-ChallengeUrl] <String> [[-Account] <Object>] [<CommonParameters>]
```

## Description

Use this after publishing the required resource for one of the challenges from an authorization object.
It lets the ACME server know that it should proceed validating that challenge. For ACME servers that allow retrying challenges, this can also be used to trigger a retry.

## Examples

### Example 1: Validate Challenge

```powershell
Send-ChallengeAck https://acme.example.com/chal/1234567
```

Validate a specific challenge URL.

### Example 2: Validate Pending HTTP Challenges

```powershell
$auths = Get-PAOrder | Get-PAAuthorization
$httpUrls = ($auths | ?{ $_.status -eq 'pending' }).HTTP01Url
$httpUrls | Send-ChallengeAck
```

Tell the ACME server to validate all pending HTTP challenges in the current order.

## Parameters

### -ChallengeUrl
The URL of the challenge to be validated.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Account
The ACME account associated with the challenge.

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
The URI of an ACME challenge object.

## Related Links

[Get-PAAuthorization](Get-PAAuthorization.md)

[Submit-ChallengeValidation](Submit-ChallengeValidation.md)
