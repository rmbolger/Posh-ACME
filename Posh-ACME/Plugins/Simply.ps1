function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$SimplyAccount,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$SimplyAPIKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$SimplyAPIKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SimplyAPIKeyInsecure = [pscredential]::new('a',$SimplyAPIKey).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.simply.com/1'
    $reqObj = @{
        'name' = $RecordName
        'type' = 'TXT'
        'data' = $TxtValue
        'ttl' = 3600
        'priority' = 0
    } | ConvertTo-Json
    $foundRecord = $false

    Write-Verbose "Finding DNS Zone"
    if (-not ($domain = Find-SimplyZone $RecordName $SimplyAccount $SimplyAPIKey)) {
        Write-Verbose "Unable to find matching zone for $recordName."
        throw "Unable to find matching zone for $RecordName."
    }
    Write-Verbose "Found domain $domain."
    $recShort = ($RecordName -ireplace [regex]::Escape($domain), [string]::Empty).TrimEnd('.')
    Write-Verbose "Accepted domain $domain and record $recShort"

    # check for an existing record
    Write-Verbose "Running: GET $apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/"
    try {
        $response = Invoke-RestMethod "$apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/" -Method Get -ContentType 'application/json' @script:UseBasic
    }
    catch {
        Write-Debug $_
        throw
    }

    Write-Verbose "Response: $response"
    foreach ($rec in $response.records) {
        Write-Debug "Records loop: $rec looking for $recShort"
        if ($rec.name -eq $recShort) {
            $foundRecord = $true
        }
    }

    if (!$foundRecord) {
        Write-Verbose "Record needs to be created."
        Write-Verbose "Running: POST $apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/"
        Write-Verbose "Record POSTed: $reqObj"
        Invoke-RestMethod "$apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/" -Method Post -Body $reqObj -ContentType 'application/json' @script:UseBasic | Out-Null
    } else {
        Write-Verbose "Record $RecordName with value $TxtValue already exists. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Simply.
    .DESCRIPTION
        Use Simply api to add a TXT record to a Simply DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER SimplyAccount
        The accountname of the account used to connect to Simply API (e.g. EU123456)
    .PARAMETER SimplyAPIKey
        The API Key associated with the account as a SecureString value. This should only be used on Windows or any OS with PowerShell 6.2+.
    .PARAMETER SimplyAPIKeyInsecure
        The API Key associated with the account as a standard string value.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxtSimply '_acme-challenge.example.com' 'txt-value' 'S123456' 'key-value'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$SimplyAccount,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$SimplyAPIKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$SimplyAPIKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SimplyAPIKeyInsecure = [pscredential]::new('a',$SimplyAPIKey).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.simply.com/1'
    $foundRecord = $false

    Write-Verbose "Finding DNS Zone"
    if (-not ($domain = Find-SimplyZone $RecordName $SimplyAccount $SimplyAPIKey)) {
        Write-Verbose "Unable to find matching zone for $recordName."
        throw "Unable to find matching zone for $RecordName."
    }
    Write-Verbose "Found $domain."
    $recShort = ($RecordName -ireplace [regex]::Escape($domain), [string]::Empty).TrimEnd('.')
    Write-Verbose "Accepted domain $domain and record $recShort"

    # check for an existing record
    Write-Verbose "Running: GET $apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/"
    try {
        $response = Invoke-RestMethod "$apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/" -Method Get -ContentType 'application/json' @script:UseBasic
    }
    catch {
        Write-Debug $_
        throw
    }

    Write-Verbose "Response: $response"
    foreach ($rec in $response.records) {
        Write-Debug "Records loop: $rec looking for $recShort"
        if ($rec.name -eq $recShort) {
            Write-Debug "Found $($rec.name) with id $($rec.record_id)"
            $foundRecord = $rec.record_id
        }
    }

    if ($foundRecord) {
        Write-Verbose "Record is being deleted."
        Write-Verbose "Running: DELETE $apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/$foundRecord"
        Invoke-RestMethod "$apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$domain/dns/records/$foundRecord" -Method Delete -ContentType 'application/json' @script:UseBasic | Out-Null
    } else {
        Write-Verbose "Record $RecordName with value $TxtValue does not exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Removes a DNS TXT record from Simply.
    .DESCRIPTION
        Use Simply api to remove a TXT record from a Simply DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER SimplyAccount
        The accountname of the account used to connect to Simply API (e.g. EU123456)
    .PARAMETER SimplyAPIKey
        The API Key associated with the account as a SecureString value. This should only be used on Windows or any OS with PowerShell 6.2+.
    .PARAMETER SimplyAPIKeyInsecure
        The API Key associated with the account as a standard string value.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxtSimply '_acme-challenge.example.com' 'txt-value' 'S123456' 'key-value'

        Removes a TXT record from the specified site with the specified value.
    #>
}

function Save-DnsTxt {
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

function Find-SimplyZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$SimplyAccount,
        [Parameter(Mandatory, Position = 2)]
        [string]$SimplyAPIKey
    )

    $apiRoot = 'https://api.simply.com/1'

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:SimplyRecordZones) { $script:SimplyRecordZones = @{} }

    # check for the record in the cache
    if ($script:SimplyRecordZones.ContainsKey($RecordName)) {
        Write-Verbose "UEZone test already ran once. Using cache to speed up process."
        return $script:SimplyRecordZones.$RecordName
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
        Write-Debug "Checking $zoneTest"

        try {
            Write-Debug "Testing domain: $apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$zoneTest/dns/records/"
            $domain = Invoke-RestMethod "$apiRoot/$SimplyAccount/$SimplyAPIKey/my/products/$zoneTest/dns/records/" -Method Get -ContentType 'application/json' @script:UseBasic
        }
        catch {
            Write-Debug "Error was caught: $_"
            # re-throw anything except a 404 because it means that something is very wrong.
            # Simply API returns code 400 no matter if it's wrong APIKey, Account or DNSZone. Therefore it's up to the next if-statement to sort it out.
            if (404 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Debug "Error was 404. Throwing error."
                throw
            }
            Write-Debug "Error was not 404 and will carry on."
            continue
        }

        Write-Debug "Test: $domain"
        if ($domain.status -eq '200') {
            Write-Verbose "Test complete. Accecpted: $zoneTest"
            $script:SimplyRecordZones.$RecordName = $zoneTest
            return $zoneTest
        } else {
            Write-Verbose "Found $zoneTest, but status was $($domain.status)"
        }
    }

    return $null
}
