function Add-DnsTxtNameCom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NameComUsername,
        [Parameter(Mandatory,Position=3)]
        [string]$NameComToken,
        [switch]$NameComUseTestEnv,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.name.com/v4'
    if ($NameComUseTestEnv) { $apiRoot = 'https://api.dev.name.com/v4' }

    $restParams = Get-RestHeaders $NameComUsername $NameComToken

    # check for an existing record
    $domainName,$rec = Get-NameComTxtRecord $RecordName $TxtValue $restParams $apiRoot

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    } else {
        # build the body
        $hostShort = ($RecordName -ireplace [regex]::Escape($domainName), [string]::Empty).TrimEnd('.')
        $bodyJson = @{host=$hostShort; type='TXT'; answer=$TxtValue; ttl=300} | ConvertTo-Json -Compress
        Write-Debug "Add JSON: $bodyJson"

        # add the new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $url = "$apiRoot/domains/$($domainName)/records"
            Invoke-RestMethod $url -Method Post -Body $bodyJson @restParams @script:UseBasic -EA Stop | Out-Null
        } catch { throw }
    }




    <#
    .SYNOPSIS
        Add a DNS TXT record to Name.com DNS.

    .DESCRIPTION
        Add a DNS TXT record to Name.com DNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NameComUsername
        The account API username.

    .PARAMETER NameComToken
        The account API token.

    .PARAMETER NameComUseTestEnv
        If specified, use the name.com testing environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtNameCom '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'username' 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtNameCom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NameComUsername,
        [Parameter(Mandatory,Position=3)]
        [string]$NameComToken,
        [switch]$NameComUseTestEnv,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.name.com/v4'
    if ($NameComUseTestEnv) { $apiRoot = 'https://api.dev.name.com/v4' }

    $restParams = Get-RestHeaders $NameComUsername $NameComToken

    # check for an existing record
    $domainName,$rec = Get-NameComTxtRecord $RecordName $TxtValue $restParams $apiRoot

    if ($rec) {
        # remove the record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $url = "$apiRoot/domains/$($domainName)/records/$($rec.id)"
            Invoke-RestMethod $url -Method Delete @restParams @script:UseBasic -EA Stop | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }




    <#
    .SYNOPSIS
        Remove a DNS TXT record from Name.com DNS.

    .DESCRIPTION
        Remove a DNS TXT record from Name.com DNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NameComUsername
        The account API username.

    .PARAMETER NameComToken
        The account API token.

    .PARAMETER NameComUseTestEnv
        If specified, use the name.com testing environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtNameCom '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'username' 'xxxxxxxxxxxx'

        Remove a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtNameCom {
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
# https://www.name.com/api-docs/DNS

function Find-NameComZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams,
        [Parameter(Mandatory,Position=2)]
        [string]$ApiRoot
    )

    # This provider doesn't appear to host sub-zones. But their API is nice enough to return the apex
    # domain automatically when using their GetDomain method even if you pass it a record within that
    # domain.
    # https://www.name.com/api-docs/Domains#GetDomain

    # So we just have to call it once and assuming they have a domain for that record, it'll return
    # the apex that we care about for later calls.
    try {
        $url = "$ApiRoot/domains/$RecordName"
        $domain = Invoke-RestMethod $url @RestParams @script:UseBasic -EA Stop

        if ($domain -and $domain.domainName) {
            return $domain.domainName
        }
    } catch {
        # if domain doesn't exist in their account, they throw a 404 which we'll catch
        # here and just ignore.
    }

    return $null
}

function Get-NameComTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$RestParams,
        [Parameter(Mandatory,Position=3)]
        [string]$ApiRoot
    )

    # Find the zone apex based on the record name
    $zoneName = Find-NameComZone $RecordName $RestParams $ApiRoot
    if (-not $zoneName) {
        throw "Domain not found for $RecordName"
    }

    # Unfortunately, there's no way to get a specific record without knowing it's ID. So we have to list (and
    # potentially page through) all of them and filter the results on our side.
    # https://www.name.com/api-docs/DNS#ListRecords

    $recs = @()
    $nextPage = ''
    do {
        $url = "$ApiRoot/domains/$zoneName/records$nextPage"
        Write-Debug "Fetching records page"
        $response = Invoke-RestMethod $url @RestParams @script:UseBasic -EA Stop
        if ($response.records) {
            $recs += $response.records
        }

        # check for paging
        if ([String]::IsNullOrWhiteSpace($response.nextPage)) { break }
        $nextPage = "?page=$($response.nextPage)"
    } while ($true)

    # Return the zone in case the record doesn't exist and the record that matches the specified $RecordName
    $rec = ($recs | Where-Object { $_.fqdn -eq "$RecordName." -and $_.answer -eq $TxtValue -and $_.type -eq 'TXT' })
    return $zoneName,$rec
}

function Get-RestHeaders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$NameComUsername,
        [Parameter(Mandatory,Position=1)]
        [string]$NameComUserToken
    )

    $restParams = @{
        Headers = @{
            Accept='application/json'
            Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $NameComUserName,$NameComToken)))
        }
        ContentType = 'application/json'
    }

    return $restParams
}
