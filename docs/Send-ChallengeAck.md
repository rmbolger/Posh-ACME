---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Send-ChallengeAck

## SYNOPSIS
Notify the ACME server to proceed validating a challenge.

## SYNTAX

```
Send-ChallengeAck [-ChallengeUrl] <String> [[-Account] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Use this after publishing the required resource for one of the challenges from an authorization object.
It lets the ACME server know that it should proceed validating that challenge.

## EXAMPLES

### EXAMPLE 1
```
$auths = Get-PAOrder | Get-PAAuthorization
```

PS C:\\\>Send-ChallengeAck $auths\[0\].DNS01Url

Tell the ACME server to validate the first DNS challenge in the current order.

### EXAMPLE 2
```
$auths = Get-PAOrder | Get-PAAuthorization
```

PS C:\\\>$httpUrls = ($auths | ?{ $_.status -eq 'pending' }).HTTP01Url
PS C:\\\>$httpUrls | Send-ChallengeAck

Tell the ACME server to validate all pending HTTP challenges in the current order.

## PARAMETERS

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PAAuthorization]()

[Submit-ChallengeValidation]()
