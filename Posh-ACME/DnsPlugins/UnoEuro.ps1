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
    $UEDNSExists = $false

    Write-Verbose "[UE-Plugin] Finding DNS Zone"
    if (-not ($UEDomain = Find-UEZone $RecordName $UEAccount $UEAPIKey)) {
        Write-Verbose "[UE Plugin] Unable to find matching zone for $recordName."
        throw "Unable to find matching zone for $RecordName."
    }
    Write-Verbose "[UE-Plugin] Found domain $UEDomain."
    $UESubDomain = ($RecordName -ireplace [regex]::Escape($UEDomain), [string]::Empty).TrimEnd('.')
    Write-Verbose "[UE-Plugin] Accepted domain $UEDomain and record $UESubDomain"

    # check for an existing record
    Write-Verbose "[UE-Plugin] Running: GET $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/"
    try {
        $UEResponse = Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Get -ContentType 'application/json' @script:UseBasic
    }
    catch {
        Write-Debug $_
        throw
    }

    Write-Verbose "[UE-Plugin] Response: $UEResponse"
    foreach ($UEDNSRecord in $UEResponse.records) {
        Write-Debug "[UE Plugin] Records loop: $UEDNSRecord looking for $UESubDomain"
        if ($UEDNSRecord.name -eq $UESubDomain) {
            $UEDNSExists = $true
        }
    }

    if (!$UEDNSExists) {
        Write-Verbose "[UE-Plugin] Record needs to be created."
        Write-Verbose "[UE-Plugin] Running: POST $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/"
        Write-Verbose "[UE-Plugin] Record POSTed: $UERequestObj"
        Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Post -Body $UERequestObj -ContentType 'application/json' @script:UseBasic | Out-Null
    } else {
        Write-Verbose "[UE Plugin] Record $RecordName with value $TxtValue already exists. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to UnoEuro.
    .DESCRIPTION
        Use UnoEuro api to add a TXT record to a UnoEuro DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER UEAccountName
        The accountname of the account used to connect to UnoEuro API (e.g. EU123456)
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
    $UEDNSExists = $false

    Write-Verbose "[UE Plugin] Finding DNS Zone"
    if (-not ($UEDomain = Find-UEZone $RecordName $UEAccount $UEAPIKey)) {
        Write-Verbose "[UE Plugin] Unable to find matching zone for $recordName."
        throw "Unable to find matching zone for $RecordName."
    }
    Write-Verbose "[UE Plugin] Found $UEDomain."
    $UESubDomain = ($RecordName -ireplace [regex]::Escape($UEDomain), [string]::Empty).TrimEnd('.')
    Write-Verbose "[UE Plugin] Accepted domain $UEDomain and record $UESubDomain"

    # check for an existing record
    Write-Verbose "[UE Plugin] Running: GET $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/"
    try {
        $UEResponse = Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Get -ContentType 'application/json' @script:UseBasic
    }
    catch {
        Write-Debug $_
        throw
    }

    Write-Verbose "[UE Plugin] Response: $UEResponse"
    foreach ($UEDNSRecord in $UEResponse.records) {
        Write-Debug "[UE Plugin] Records loop: $UEDNSRecord looking for $UESubDomain"
        if ($UEDNSRecord.name -eq $UESubDomain) {
            Write-Debug '[UE Plugin] Found $UEDNSRecord.name with id $UEDNSRecord.record_id'
            $UEDNSExists = $UEDNSRecord.record_id
        }
    }

    Write-Verbose "[UE Plugin] Continuing with DNSExists: $UEDNSExists"
    if ($UEDNSExists) {
        Write-Verbose "[UE Plugin] Record is being deleted."
        Write-Verbose "[UE Plugin] Running: DELETE $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/$UEDNSExists"
        Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/$UEDNSExists -Method Delete -ContentType 'application/json' @script:UseBasic | Out-Null
    } else {
        Write-Verbose "[UE Plugin] Record $RecordName with value $TxtValue does not exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Removes a DNS TXT record from UnoEuro.
    .DESCRIPTION
        Use UnoEuro api to remove a TXT record from a UnoEuro DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER UEAccountName
        The accountname of the account used to connect to UnoEuro API (e.g. EU123456)
    .PARAMETER UEAPIKey
        The API Key associated with the account entered in the UEAccountName parameter.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxtUnoEuro '_acme-challenge.example.com' 'asdfqwer12345678' 'UE123456' 'ABCDEFghijkLmNoPq' 'example.com'
        Removes a TXT record from the specified site with the specified value.
    #>
}

function Save-DnsTxtUnoEuro {
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

function Find-UEZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$UEAccount,
        [Parameter(Mandatory, Position = 2)]
        [string]$UEAPIKey
    )

    $UEApiRoot = 'https://api.unoeuro.com/1'

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:UERecordZones) { $script:UERecordZones = @{} }

    # check for the record in the cache
    if ($script:UERecordZones.ContainsKey($RecordName)) {
        Write-Verbose "[UE Plugin] UEZone test already ran once. Using cache to speed up process."
        return $script:UERecordZones.$RecordName
    }

    # We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "[UE Plugin] Checking $zoneTest"

        try {
            Write-Debug "[UE Plugin] Testing domain: $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$zoneTest/dns/records/"
            $domain = Invoke-RestMethod "$UEApiRoot/$UEAccount/$UEAPIKey/my/products/$zoneTest/dns/records/" -Method Get -ContentType 'application/json' @script:UseBasic
        }
        catch {
            Write-Debug "[UE Plugin] Error was caught: $_"
            # re-throw anything except a 404 because it means that something is very wrong.
            # UnoEuro API returns code 400 no matter if it's wrong APIKey, Account or DNSZone. Therefore it's up to the next if-statement to sort it out.
            if (404 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Debug "[UE Plugin] Error was 404. Throwing error."
                throw
            }
            Write-Debug "[UE Plugin] Error was not 404 and will carry on."
            continue
        }

        Write-Debug "[UE Plugin] Test: $domain"
        if ($domain.status -eq '200') {
            Write-Verbose "[UE Plugin] Test complete. Accecpted: $zoneTest"
            $script:UERecordZones.$RecordName = $zoneTest
            return $zoneTest
        } else {
            Write-Verbose "[UE Plugin] Found $zoneTest, but status was $($domain.status)"
        }
    }

    return $null

    <#
    .SYNOPSIS
        Finds the appropriate DNS zone for the supplied record
    .DESCRIPTION
        Finds the appropriate DNS zone for the supplied record
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER UEAccount
        The UnoEuro account ID or name.
    .PARAMETER UEAPIKey
        The UnoEuro API Key.
    .EXAMPLE
        Find-UEZone -RecordName '_acme-challenge.site1.example.com' -GDKey 'asdfqwer12345678' -GDSecret 'dfasdasf3j42f'
        Finds the appropriate DNS zone for the supplied record
    #>
}
