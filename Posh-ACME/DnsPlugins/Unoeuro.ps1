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

    Write-Debug "Finding DNS Zone"
    if (-not ($UEDomain = Find-UEZone $RecordName $UEAccount $UEAccount)) {
        Write-Debug "Unable to find matching zone for $recordName."
        throw "Unable to find matching zone for $RecordName."
    }
    Write-Debug "Found $UEDomain. Isolating."
    $UESubDomain = $RecordName -ireplace [regex]::Escape(".$UEDomain"), [string]::Empty
    Write-Debug "Accepted domain $UEDomain and record $UESubDomain"

    # check for an existing record
    Write-Debug "Running: GET $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/"
    try {
        $UEResponse = Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Get -ContentType 'application/json'
    }
    catch {
        Write-Debug $_
        throw
    }

    Write-Debug "Response: $UEResponse"
    foreach ($UEDNSRecord in $UEResponse.records) {
        Write-Debug "Record: $UEDNSRecord looking for $UESubDomain"
        if ($UEDNSRecord.name -eq $UESubDomain) {
            $UEDNSExists = $true
        }
    }

    if (!$UEDNSExists) {
        Write-Debug "Record needs to be created."
        Write-Debug "POST: $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/"
        Invoke-RestMethod $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$UEdomain/dns/records/ -Method Post -Body $UERequestObj -ContentType 'application/json'
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
        Write-Debug "Test already ran once. Using cache to speed up process."
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
    for ($i = 1; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        try {
            Write-Debug "Testing domain: $UEApiRoot/$UEAccount/$UEAPIKey/my/products/$zoneTest/dns/records/"
            $domain = Invoke-RestMethod "$UEApiRoot/$UEAccount/$UEAPIKey/my/products/$zoneTest/dns/records/" -Method Get -ContentType 'application/json'
        }
        catch {
            Write-Debug "Error was caught: $_"
            # re-throw anything except a 404 because it means that something is very wrong.
            # Unoeuro API returns code 400 no matter if it's wrong APIKey, Account or DNSZone. Therefore it's up to the next if-statement to sort it out.
            if (404 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Debug "Error was 404. Throwing error."
                throw
            }
            Write-Debug "Error was not 404 and will carry on."
            continue
        }

        Write-Debug "Test: $domain"
        if ($domain.status -eq '200') {
            Write-Debug "Test complete. Accecpted: $zoneTest"
            $script:UERecordZones.$RecordName = $zoneTest
            return $zoneTest
        } else {
            Write-Debug "Found $zoneTest, but status was $($domain.status)"
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
        The Unoeuro account ID or name.
    .PARAMETER UEAPIKey
        The Unoeuro API Key.
    .EXAMPLE
        Find-UEZone -RecordName '_acme-challenge.site1.example.com' -GDKey 'asdfqwer12345678' -GDSecret 'dfasdasf3j42f'
        Finds the appropriate DNS zone for the supplied record
    #>
}