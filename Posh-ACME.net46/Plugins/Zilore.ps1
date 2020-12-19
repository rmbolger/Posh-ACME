function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [securestring]$ZiloreKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiBase = "https://api.zilore.com/dns/v1/domains"

    # convert the key to plaintext and add it to an auth header
    $zkey = [pscredential]::new('a',$ZiloreKey).GetNetworkCredential().Password
    $authHeader = @{'X-Auth-Key' = $zkey}

    # find the zone to host the record
    if (-not ($zone = Find-ZiloreZone $RecordName $authHeader)) {
        throw "Unable to find matching zone for $RecordName."
    }

    # query existing records
    $uri = "$apiBase/$zone/records?search_text=$RecordName&strict_search=yes&search_record_type=TXT"
    try {
        $response = Invoke-RestMethod $uri -Headers $authHeader -EA Stop @script:UseBasic
        $rec = $response.response | Where-Object { $_.record_value -eq "`"$TxtValue`"" }
    } catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # add the new record
        $addParams = @{
            Uri = "$apiBase/$zone/records"
            Body = @{
                record_name = $RecordName
                record_value = "`"$TxtValue`""
                record_type = 'TXT'
                record_ttl = 300
            }
            Method = 'POST'
            Headers = $authHeader
            ErrorAction = 'Stop'
        }
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            Invoke-RestMethod @addParams @script:UseBasic | Out-Null
        } catch { throw }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Zilore

    .DESCRIPTION
        Add a DNS TXT record to Zilore

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZiloreKey
        Your Zilore API key as a SecureString value.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' (Read-Host "API Key" -AsSecureString)

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [securestring]$ZiloreKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiBase = "https://api.zilore.com/dns/v1/domains"

    # convert the key to plaintext and add it to an auth header
    $zkey = [pscredential]::new('a',$ZiloreKey).GetNetworkCredential().Password
    $authHeader = @{'X-Auth-Key' = $zkey}

    # find the zone to host the record
    if (-not ($zone = Find-ZiloreZone $RecordName $authHeader)) {
        throw "Unable to find matching zone for $RecordName."
    }

    # query existing records
    $uri = "$apiBase/$zone/records?search_text=$RecordName&strict_search=yes&search_record_type=TXT"
    try {
        $response = Invoke-RestMethod $uri -Headers $authHeader -EA Stop @script:UseBasic
        $rec = $response.response | Where-Object { $_.record_value -eq "`"$TxtValue`"" }
    } catch { throw }

    if ($rec) {
        # remove the new record
        $delParams = @{
            Uri = "$apiBase/$zone/records?record_id=$($rec.record_id)"
            Method = 'DELETE'
            Headers = $authHeader
            ErrorAction = 'Stop'
        }
        try {
            Write-Verbose "Removing a TXT record $($rec.record_id) for $RecordName with value $TxtValue"
            Invoke-RestMethod @delParams @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record to Zilore

    .DESCRIPTION
        Remove a DNS TXT record to Zilore

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZiloreKey
        Your Zilore API key as a SecureString value.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' (Read-Host "API Key" -AsSecureString)

        Removes a TXT record for the specified site with the specified value.
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

# API Docs
# https://zilore.com/en/help/api

function Find-ZiloreZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$AuthHeader
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!(Get-Variable -Scope Script -Name 'ZiloreRecordZones' -EA SilentlyContinue)) {
        $script:ZiloreRecordZones = @{}
    }

    # check for the record in the cache
    if ($script:ZiloreRecordZones.ContainsKey($RecordName)) {
        return $script:ZiloreRecordZones.$RecordName
    }

    # Determine origin for zone
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug ("Checking {0}" -f $zoneTest)
        try {
            # Be aware: this query returns partial zone name matches so domain=example.com will return
            # both example.com and myexample.com
            $queryParams = @{
                Uri = "https://api.zilore.com/dns/v1/domains?search_text=$zoneTest"
                Method = 'GET'
                Headers = $AuthHeader
                ErrorAction = 'Stop'
            }
            $response = Invoke-RestMethod @queryParams @script:UseBasic

            # check for results
            if ($response.response.Count -gt 0 -and $zoneTest -in $response.response.domain_name) {
                Write-Debug "Found DNS zone $zoneTest"
                # Cache response
                $script:ZiloreRecordZones.$RecordName = $zoneTest
                return $zoneTest
            }
        } catch { throw }
    }

    return $null
}
