function Add-DnsTxtAliyun {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AliKeyId,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$AliSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$AliSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the insecure secret to a securestring
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $AliSecret = ConvertTo-SecureString $AliSecretInsecure -AsPlainText -Force
    }

    # find the zone for this record
    try { $zoneName = Find-AliZone $RecordName $AliKeyId $AliSecret } catch { throw }
    Write-Debug "Found zone $zoneName"

    # grab the relative portion of the fqdn
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if ($recShort -eq $RecordName) { $recShort = '@' }

    # query for an existing record
    try {
        $queryParams = "DomainName=$zoneName","RRKeyWord=$recShort","ValueKeyWord=$TxtValue",'TypeKeyWord=TXT'
        $response = Invoke-AliRest DescribeDomainRecords $queryParams $AliKeyId $AliSecret
    } catch { throw }

    if ($response.TotalCount -gt 0) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # add the record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $queryParams = "DomainName=$zoneName","RR=$recShort","Value=$TxtValue",'Type=TXT'
        Invoke-AliRest AddDomainRecord $queryParams $AliKeyId $AliSecret | Out-Null
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Aliyun (Alibaba Cloud)

    .DESCRIPTION
        Add a DNS TXT record to Aliyun (Alibaba Cloud)

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AliKeyId
        The Access Key ID for your Aliyun account.

    .PARAMETER AliSecret
        The Access Secret for your Aliyun account. This SecureString version should only be used on Windows.

    .PARAMETER AliSecretInsecure
        The Access Secret for your Aliyun account. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "Secret" -AsSecureString
        PS C:\>Add-DnsTxtAliyun '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'asdf1234' $secret

        Adds a TXT record using a securestring object for AliSecret. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxtAliyun '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'asdf1234' 'xxxxxxxx'

        Adds a TXT record using a standard string object for AliSecretInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxtAliyun {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AliKeyId,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$AliSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$AliSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the insecure secret to a securestring
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $AliSecret = ConvertTo-SecureString $AliSecretInsecure -AsPlainText -Force
    }

    # find the zone for this record
    try { $zoneName = Find-AliZone $RecordName $AliKeyId $AliSecret } catch { throw }
    Write-Debug "Found zone $zoneName"

    # grab the relative portion of the fqdn
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if ($recShort -eq $RecordName) { $recShort = '@' }

    # query for an existing record
    try {
        $queryParams = "DomainName=$zoneName","RRKeyWord=$recShort","ValueKeyWord=$TxtValue",'TypeKeyWord=TXT'
        $response = Invoke-AliRest DescribeDomainRecords $queryParams $AliKeyId $AliSecret
    } catch { throw }

    if ($response.TotalCount -gt 0) {
        # remove the record
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        $id = $response.DomainRecords.Record[0].RecordId
        Invoke-AliRest DeleteDomainRecord @("RecordId=$id") $AliKeyId $AliSecret | Out-Null
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Aliyun (Alibaba Cloud)

    .DESCRIPTION
        Remove a DNS TXT record from Aliyun (Alibaba Cloud)

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AliKeyId
        The Access Key ID for your Aliyun account.

    .PARAMETER AliSecret
        The Access Secret for your Aliyun account. This SecureString version should only be used on Windows.

    .PARAMETER AliSecretInsecure
        The Access Secret for your Aliyun account. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "Secret" -AsSecureString
        PS C:\>Remove-DnsTxtAliyun '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'asdf1234' $secret

        Removes a TXT record using a securestring object for AliSecret. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxtAliyun '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'asdf1234' 'xxxxxxxx'

        Removes a TXT record using a standard string object for AliSecretInsecure. (Use this on non-Windows)
    #>
}

function Save-DnsTxtAliyun {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://www.alibabacloud.com/help/doc-detail/34272.htm?spm=a2c63.p38356.b99.28.5afd3c15JLzC0y

function Invoke-AliRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Action,
        [Parameter(Position=1)]
        [string[]]$ActionParams,
        [Parameter(Mandatory,Position=2)]
        [string]$AccessKeyId,
        [Parameter(Mandatory,Position=3)]
        [securestring]$AccessSecret
    )

    $apiBase = 'https://alidns.aliyuncs.com'

    # Signature mechanism
    # https://www.alibabacloud.com/help/doc-detail/34279.htm?spm=a2c63.p38356.b99.35.710e28fd71zpOk
    # - all params sorted alphabetically
    # - URL (RFC3960) encoded
    #   - Docs imply '&' is not encoded, but the only way I made it work was encoding the ones
    #     in the param sets, but not the ones at the beginning next to the <Method>
    # - <String to Sign> = <Method>&%2F&<Params>
    # - <Signature> = URL(Base64(HMAC-SHA1(<String to Sign>))) where HMAC key is "<Secret>&"

    # build the sorted list of parameters
    $allParams = $ActionParams + @(
        "AccessKeyId=$AccessKeyId",
        "Action=$Action",
        'Format=json',
        'SignatureMethod=HMAC-SHA1',
        "SignatureNonce=$((New-Guid).ToString())",
        'SignatureVersion=1.0',
        # for some reason, Aliyun expects the ':' characters in the timestamp to be double-encoded
        # so we'll pre-encode them the first time here
        "Timestamp=$((Get-DateTimeOffsetNow).UtcDateTime.ToString('yyyy-MM-ddTHH\%3Amm\%3AssZ'))",
        "Version=2015-01-09"
    ) | Sort-Object

    # build the string to sign
    $strToSign = [uri]::EscapeDataString($allParams -join '&')
    $strToSign = "GET&%2F&$strToSign"
    Write-Debug $strToSign
    $stsBytes = [Text.Encoding]::UTF8.GetBytes($strToSign)

    # compute the signature
    $secPlain = (New-Object PSCredential "user",$AccessSecret).GetNetworkCredential().Password
    $secBytes = [Text.Encoding]::UTF8.GetBytes("$secPlain&")
    $hmac = New-Object Security.Cryptography.HMACSHA1($secBytes,$true)
    $sig = [Convert]::ToBase64String($hmac.ComputeHash($stsBytes))
    $sigUrl = [uri]::EscapeDataString($sig)
    Write-Debug $sig

    $uri = "$apiBase/?$($allParams -join '&')&Signature=$sigUrl"

    Invoke-RestMethod $uri @script:UseBasic -EA Stop
}

function Find-AliZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$AliKeyId,
        [Parameter(Mandatory,Position=2)]
        [securestring]$AliSecret
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:AliRecordZones) { $script:AliRecordZones = @{} }

    # check for the record in the cache
    if ($script:AliRecordZones.ContainsKey($RecordName)) {
        return $script:AliRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-AliRest DescribeDomains @("KeyWord=$zoneTest") $AliKeyId $AliSecret

            # check for results
            if ($response.TotalCount -gt 0) {
                $script:AliRecordZones.$RecordName = $response.Domains.Domain[0].DomainName # or PunyCode?
                return $script:AliRecordZones.$RecordName
            }
        } catch { throw }
    }

    throw "No zone found for $RecordName"
}
