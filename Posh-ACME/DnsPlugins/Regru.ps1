function Add-DnsTxtRegRu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RegRuLogin,
        [Parameter(Mandatory, Position = 3)]
        [string]$RegRuPassword,
        [Parameter(Position = 4)]
        [string]$DomainName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $ShortRecordName = $RecordName.Replace("." + $DomainName, '')

    #Check existing record
    $existingRecord = Get-RR-DnsRecordId $RegRuLogin $RegRuPassword $ShortRecordName $DomainName
    if ($existingRecord) {
        #Remove existing record before add new
        Remove-DnsTxtRegRu -RecordName $RecordName -TxtValue $existingRecord.content -RegRuLogin $RegRuLogin -RegRuPassword $RegRuPassword -DomainName $DomainName
    }

    #Add new TXT record
    $url = 'https://api.reg.ru/api/regru2/zone/add_txt?input_data='
    $reqFormat = '&input_format=json'
    $domains = @(
        @{"dname" = $DomainName }
    )
    $body = @{
        "username"            = $RegRuLogin
        "password"            = $RegRuPassword
        "domains"             = $domains
        "subdomain"           = $ShortRecordName
        "text"                = $TxtValue
        "output_content_type" = "plain"
    } | ConvertTo-Json

    $result = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $($url + $body + $reqFormat)
    if ($result.result -eq 'error') {
        throw $result.error_text
    }

    $zone = $($result.answer.domains | Where-Object { $_.dname -eq $DomainName })
    if ($zone.result -eq 'error') {
        throw $zone.error_text
    }
    else {
        $zone
    }
    <#
     .SYNOPSIS
        Remove a DNS TXT record from Reg.Ru.

    .DESCRIPTION
        Uses the Reg.Ru API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RegRuLogin
        Your Reg.Ru username.

    .PARAMETER RegRuPassword
        Your Reg.Ru account or API access password.

    .PARAMETER DomainName
        Your domain from Reg.Ru admin panel.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtRegRu '_acme-challenge.site1.domain.zone' 'asdfqwer12345678' 'user@reg.ru' 'YourPassword' 'domain.zone'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtRegRu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RegRuLogin,
        [Parameter(Mandatory, Position = 3)]
        [string]$RegRuPassword,
        [Parameter(Position = 4)]
        [string]$DomainName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $ShortRecordName = $RecordName.Replace("." + $DomainName, '')

    #Check existing record content
    $existingRecord = Get-RR-DnsRecordId $RegRuLogin $RegRuPassword $ShortRecordName $DomainName
    if ($existingRecord) {
        if ($existingRecord.content -ne $TxtValue) {
            $TxtValue = $existingRecord.content
        }
    }
    else {
        throw "existing record not found"
    }
    

    $url = 'https://api.reg.ru/api/regru2/zone/remove_record?input_data='
    $reqFormat = '&input_format=json'
    $domains = @(
        @{"dname" = $DomainName }
    )
    $body = @{
        "username"            = $RegRuLogin
        "password"            = $RegRuPassword
        "domains"             = $domains
        "subdomain"           = $ShortRecordName
        "content"             = $TxtValue  # set content of existing record to prevent unvanted removal of other records with same type
        "record_type"         = "TXT"
        "output_content_type" = "plain"
    } | ConvertTo-Json

    $result = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $($url + $body + $reqFormat)
    if ($result.result -eq 'error') {
        throw $result.error_text
    }

    $zone = $($result.answer.domains | Where-Object { $_.dname -eq $DomainName })
    if ($zone.result -eq 'error') {
        throw $zone.error_text
    }
    else {
        $zone
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Reg.Ru.

    .DESCRIPTION
        Uses the Reg.Ru API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RegRuLogin
        Your Reg.Ru username.

    .PARAMETER RegRuPassword
        Your Reg.Ru account or API access password.

    .PARAMETER DomainName
        Your domain from Reg.Ru admin panel.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtRegRu '_acme-challenge.site1.domain.zone' 'asdfqwer12345678' 'user@reg.ru' 'YourPassword' 'domain.zone'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtRegRu {
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

### Internal functions

function Get-RR-DnsRecordId {
    param (
        [Parameter(Mandatory)]
        [string]$RegRuLogin,
        [Parameter(Mandatory)]
        [string]$RegRuPassword,
        [Parameter(Mandatory)]
        $ShortRecordName,
        [Parameter(Mandatory)]
        $DomainName

    )

    $url = 'https://api.reg.ru/api/regru2/zone/get_resource_records?input_data='
    $reqFormat = '&input_format=json'
    $domains = @(
        @{"dname" = $DomainName }
    )
    $body = @{
        "username"            = $RegRuLogin
        "password"            = $RegRuPassword
        "domains"             = $domains
        "output_content_type" = "plain"
    } | ConvertTo-Json

    $result = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $($url + $body + $reqFormat)
    if ($result.result -eq 'error') {
        throw $result.error_text
    }

    $zone = $($result.answer.domains | Where-Object { $_.dname -eq $DomainName })
    if ($zone.result -eq 'error') {
        throw $zone.error_text
    }
    else {
        $record = $zone.rrs | Where-Object { $_.subname -eq $ShortRecordName -and $_.rectype -eq 'TXT' }
    }

    $record
}