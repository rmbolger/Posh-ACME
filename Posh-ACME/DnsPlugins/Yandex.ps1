function Add-DnsTxtYandex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$YandexApiKey,
        [Parameter(Position = 3)]
        [string]$DomainName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $AuthHeader = @{"PddToken" = $YandexApiKey }

    $ShortRecordName = $RecordName.Replace("." + $DomainName, '')

    # Query existing TXT record
    try {
        $dnsRecordId = ((Invoke-RestMethod -Method GET -Header $AuthHeader -ContentType "application/json" -uri "https://pddimp.yandex.ru/api2/admin/dns/list?domain=$($DomainName)").records | Where-Object { $_.subdomain -eq $ShortRecordName }).record_id
    }
    catch { throw }

    try {
        # Add the new TXT record
        if (!$dnsRecordId) {
            $body = "domain=$DomainName&type=TXT&subdomain=$ShortRecordName&ttl=1&content=$TxtValue"
            $response = Invoke-RestMethod -Method POST -Header $AuthHeader -ContentType "application/x-www-form-urlencoded" -Body $body -uri 'https://pddimp.yandex.ru/api2/admin/dns/add'
            if ($response.success -eq 'error') {
                throw $response.error
            }
    
        }
        # modify existing TXT record
        else {
            $body = "domain=$DomainName&record_id=$dnsRecordId&ttl=1&content=$TxtValue"
            $response = Invoke-RestMethod -Method POST -Header $AuthHeader -ContentType "application/x-www-form-urlencoded" -Body $body -uri 'https://pddimp.yandex.ru/api2/admin/dns/edit'
            if ($response.success -eq 'error') {
                throw $response.error
            }
        }    
    }
    catch { throw }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Yandex.

    .DESCRIPTION
        Uses the Yandex DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER YandexApiKey
        Your Yandex DNS API key.

    .PARAMETER DomainName
        Your domain from Yandex admin panel.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtYandex '_acme-challenge.site1.domain.zone' 'asdfqwer12345678' 'domain.zone'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtYandex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$YandexApiKey,
        [Parameter(Position = 3)]
        [string]$DomainName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $AuthHeader = @{"PddToken" = $YandexApiKey }
    
    $ShortRecordName = $RecordName.Replace("." + $DomainName, '')

    # Query existing TXT record
    try {
        $dnsRecordId = (Invoke-RestMethod -Method GET -Header $AuthHeader -ContentType "application/json" -uri "https://pddimp.yandex.ru/api2/admin/dns/list?domain=$($DomainName)").records | Where-Object { $_.subdomain -eq $ShortRecordName }
    }
    catch { throw }

    try {
        
        $body = "domain=$DomainName&record_id=$dnsRecordId"
        $response = Invoke-RestMethod -Method POST -Header $AuthHeader -ContentType "application/x-www-form-urlencoded" -Body $body -uri 'https://pddimp.yandex.ru/api2/admin/dns/del'
        if ($response.success = 'error') {
            throw $response.error
        }        
    }
    catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Yandex.

    .DESCRIPTION
        Uses the Yandex DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER YandexApiKey
        Your Yandex DNS API key.

    .PARAMETER DomainName
        Your domain from Yandex admin panel.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtyandex '_acme-challenge.site1.domain.zone' 'asdfqwer12345678' 'domain.zone'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtYandex {
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
