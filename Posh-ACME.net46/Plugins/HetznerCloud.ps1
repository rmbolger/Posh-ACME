function Get-CurrentPluginType { 'dns-01' }

Function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position = 2)]
        [securestring]$HCToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # un-secure the password so we can add it to the auth header
    $HCTokenInsecure = [pscredential]::new('a',$HCToken).GetNetworkCredential().Password
    $restParams = @{
        Headers = @{
            Authorization = "Bearer $HCTokenInsecure"
            Accept = 'application/json'
        }
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-HetznerZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.name.TrimEnd('.')))$",''
    if ($recShort -eq '') { $recShort = '@' }

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $query = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets?type=TXT&name=$recShort"
        Write-Debug "GET $query"
        $recs = Invoke-RestMethod $query @restParams @Script:UseBasic
        Write-Debug ($recs | ConvertTo-Json -Depth 5)
    } catch {
        if (404 -ne $_.Exception.Response.StatusCode) {
            throw
        }
    }

    # check for a matching record. Partially redacted example follows:
    # {
    #   "meta": { ... },
    #   "rrsets": [
    #     {
    #       "id": "_acme-challenge/TXT",
    #       "name": "_acme-challenge",
    #       "type": "TXT",
    #       "ttl": 600,
    #       "records": [
    #         {
    #           "value": "\"3Sf2LzKsq12Av-nfduZjxebiOd2FhccQXeLVx5eDrGM\"",
    #           "comment": "ACME cert validation"
    #         }
    #       ],
    #       "zone": 69323
    #     }
    #   ]
    # }
    $rec = $recs.rrsets[0]
    $valToFind = "`"$TxtValue`""

    if ($rec) {
        # check if the value already exists
        if ($valToFind -in $rec.records.value) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
            return
        }
        # add the new value
        $queryParams = @{
            Uri = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets/$($rec.id)/actions/add_records"
            Method = 'POST'
            Body = @{
                records = @(@{
                    value = $valToFind
                    comment = "ACME cert validation"
                })
            } | ConvertTo-Json
        }

        Write-Verbose "Update Record $RecordName with new value $TxtValue."

    } else {
        # add a new record
        $queryParams = @{
            Uri = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets"
            Method = 'POST'
            Body = @{
                name = $recShort
                type = 'TXT'
                ttl = 300
                records = @(@{
                    value = $valToFind
                    comment = "ACME cert validation"
                })
            } | ConvertTo-Json
        }

        Write-Verbose "Add Record $RecordName with value $TxtValue."
    }

    try {
        Write-Debug "$($queryParams.Method) $($queryParams.Uri)`n$($queryParams.Body)"
        $null = Invoke-RestMethod @queryParams @restParams @Script:UseBasic
    } catch { throw }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Hetzner.
    .DESCRIPTION
        Uses the Hetzner DNS API to add or update a DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER HCToken
        The API token for your Hetzner account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HCToken $token

        Adds or updates the specified TXT record with the specified value.
    #>
}

Function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position = 2)]
        [securestring]$HCToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # un-secure the password so we can add it to the auth header
    $HCTokenInsecure = [pscredential]::new('a',$HCToken).GetNetworkCredential().Password
    $restParams = @{
        Headers = @{
            Authorization = "Bearer $HCTokenInsecure"
            Accept = 'application/json'
        }
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-HetznerZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.name.TrimEnd('.')))$",''
    if ($recShort -eq '') { $recShort = '@' }

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $query = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets?type=TXT&name=$recShort"
        Write-Debug "GET $query"
        $recs = Invoke-RestMethod $query @restParams @Script:UseBasic
        Write-Debug ($recs | ConvertTo-Json -Depth 5)
    } catch {
        if (404 -ne $_.Exception.Response.StatusCode) {
            throw
        }
    }

    # check for a matching record
    $rec = $recs.rrsets[0]
    $valToFind = "`"$TxtValue`""

    if ($rec) {
        if (-not ($valToFind -in $rec.records.value)) {
            Write-Debug "Record $RecordName does not contain $TxtValue. Nothing to do."
            return
        }

        if ($rec.records.Count -gt 1) {
            # remove just the one value
            $queryParams = @{
                Uri = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets/$($rec.id)/actions/remove_records"
                Method = 'POST'
                Body = @{
                    records = @(@{
                        value = $valToFind
                    })
                } | ConvertTo-Json
            }
            Write-Verbose "Remove value $TxtValue from Record $RecordName."
            Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
        } else {
            # remove the entire record set
            $queryParams = @{
                Uri = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets/$($rec.id)"
                Method = 'DELETE'
            }
            Write-Verbose "Remove Record $RecordName with value $TxtValue."
            Write-Debug "DELETE $($queryParams.Uri)"
        }

        try {
            $null = Invoke-RestMethod @queryParams @restParams @Script:UseBasic
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Hetzner.
    .DESCRIPTION
        Uses the Hetzner DNS API to remove DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER HCToken
        The API token for your Hetzner account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HCToken $token

        Removes the specified TXT record with the specified value.
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

# API Docs: https://docs.hetzner.cloud/reference/cloud#dns

Function Find-HetznerZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position=1)]
        [hashtable]$RestParameters
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:HCRecordZones) { $script:HCRecordZones = @{} }

    # check for the record in the cache
    if ($script:HCRecordZones.ContainsKey($RecordName)) {
        Write-Debug "Result from Cache $($script:HCRecordZones.$RecordName.Name)"
        return $script:HCRecordZones.$RecordName
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
            $query = "https://api.hetzner.cloud/v1/zones/$zoneTest"
            Write-Debug "GET $query"
            $response = Invoke-RestMethod $query @RestParameters @Script:UseBasic
        } catch {
            if (404 -eq $_.Exception.Response.StatusCode) {
                Write-Debug "Zone $zoneTest does not exist"
                continue
            }
            else { throw }
        }

        if(!$response.zone) {
            return $null;
        }

        Write-Debug "Zone $zoneTest found"

        $zone = @{
            id = ($response.zone.id)
            name = ($response.zone.name)
        }

        $script:HCRecordZones.$RecordName = $zone
        return $zone
    }

    return $null
}
