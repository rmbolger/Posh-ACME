function Add-DnsTxtUnoEuro {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$UEAccount,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [string]$UEAPIKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $UEApiRoot = 'https://api.unoeuro.com/1'
    $UERequestObj = [PSCustomObject]@{
        'name' = $RecordName
        'type' = 'TXT'
        'data' = $TxtValue
        'ttl' = 3600
        'priority' = 0
    } | ConvertTo-Json
    $DomainRegex = '([0-9a-z-]{2,}\.[0-9a-z-]{2,3}\.[0-9a-z-]{2,3}|[0-9a-z-]{2,}\.[0-9a-z-]{2,3})$'
    $UEDomain = [Regex]::Match($RecordName, $DomainRegex).value
    $UEDNSExists = $false

    # check for an existing record
    $UEResponse = Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Get -ContentType 'application/json' @script:UseBasic
    
    foreach ($UEDNSRecord in $UEResponse.records) {
        if ($UEDNSRecord.name -eq ([Regex]::Replace($RecordName, [Regex]::Match($RecordName, '.'+$DomainRegex).value, ''))) {
            $UEDNSExists = $true
        }
    }

    if (!$UEDNSExists) {
        Write-Debug "Record needs to be created."
        Write-Debug "Running URL: $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/"
        Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Post -Body $UERequestObj -ContentType 'application/json' @script:UseBasic | Out-Null
    } else {
        Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Unoeuro.
    .DESCRIPTION
        Use Unoeuro api to add a TXT record to a Unoeuro DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER UEAccountName
        The accountname of the account used to connect to Unoeuro API (e.g. EU123456)
    .PARAMETER UEAPIKey
        The API Key associated with the account entered in the UEAccountName parameter.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxtUnoEuro '_acme-challenge.example.com' 'asdfqwer12345678' 'UE123456' 'ABCDEFghijkLmNoPq' 'example.com'
        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtUnoEuro {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$UEAccount,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [string]$UEAPIKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $UEApiRoot = 'https://api.unoeuro.com/1'
    $DomainRegex = '([0-9a-z-]{2,}\.[0-9a-z-]{2,3}\.[0-9a-z-]{2,3}|[0-9a-z-]{2,}\.[0-9a-z-]{2,3})$'
    $UEDomain = [Regex]::Match($RecordName, $DomainRegex).value
    $UEDNSExists = $false

    # check for an existing record
    $UEResponse = Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Get -ContentType 'application/json' @script:UseBasic
    
    foreach ($UEDNSRecord in $UEResponse.records) {
        if ($UEDNSRecord.name -eq ([Regex]::Replace($RecordName, [Regex]::Match($RecordName, '.'+$DomainRegex).value, ''))) {
            Write-Verbose 'Found $UEDNSRecord.name with id $UEDNSRecord.record_id'
            $UEDNSExists = $UEDNSRecord.record_id
        }
    }

    if ($UEDNSExists) {
        Write-Verbose "Record is being deleted."
        Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/$UEDNSExists -Method Delete -ContentType 'application/json' @script:UseBasic | Out-Null
    } else {
        Write-Debug "Record $RecordName with value $TxtValue does not exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Removes a DNS TXT record from Unoeuro.
    .DESCRIPTION
        Use Unoeuro api to remove a TXT record from a Unoeuro DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER UEAccountName
        The accountname of the account used to connect to Unoeuro API (e.g. EU123456)
    .PARAMETER UEAPIKey
        The API Key associated with the account entered in the UEAccountName parameter.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxtUnoEuro '_acme-challenge.example.com' 'asdfqwer12345678' 'UE123456' 'ABCDEFghijkLmNoPq' 'example.com'
        Removes a TXT record from the specified site with the specified value.
    #>
}

function Save-DnsTxtUnoeuro {
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