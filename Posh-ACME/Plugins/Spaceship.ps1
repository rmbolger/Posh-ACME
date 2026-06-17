function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [pscredential]$SpaceshipCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # normalize TXT record value by stripping quotes since API doesn't need them
    $TxtValue = $TxtValue.Trim('"')

    # create common params for REST calls
    $restParams = @{
        Headers = @{
            'X-API-Key' = $SpaceshipCredential.UserName
            'X-API-Secret' = $SpaceshipCredential.GetNetworkCredential().Password
        }
        Verbose = $false
        Debug = $false
        ErrorAction = 'Stop'
    } + $script:UseBasic

    $zone,$recs = Find-SpaceshipRecords $RecordName $restParams
    Write-Debug "Found $zone and $($recs.Count) records"

    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    if ($recShort -eq '') { $recShort = '@' }

    $rec = $recs | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $recShort -and
        $_.value -eq $TxtValue
    }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        $addParams = $restParams + @{
            Uri = 'https://spaceship.dev/api/v1/dns/records/{0}' -f $zone
            Method = 'PUT'
            ContentType = 'application/json'
            Body = @{
                force = $true
                items = @(
                    @{
                        type = 'TXT'
                        name = $recShort
                        value = $TxtValue
                        ttl = 60
                    }
                )
            } | ConvertTo-Json -Compress
        }
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Write-Debug "PUT $($addParams.Uri)`n$($addParams.Body)"
        Invoke-RestMethod @addParams
    }



    <#
    .SYNOPSIS
        Add a DNS TXT record to Spaceship

    .DESCRIPTION
        Add a DNS TXT record to Spaceship

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SpaceshipCredential
        A PSCredential object containing the API key and secret for authenticating to the Spaceship API. The API key should be entered as the username and the API secret should be entered as the password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' (Get-Credential)

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
        [Parameter(Mandatory,Position=2)]
        [pscredential]$SpaceshipCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # normalize TXT record value by stripping quotes since API doesn't need them
    $TxtValue = $TxtValue.Trim('"')

    # create common params for REST calls
    $restParams = @{
        Headers = @{
            'X-API-Key' = $SpaceshipCredential.UserName
            'X-API-Secret' = $SpaceshipCredential.GetNetworkCredential().Password
        }
        Verbose = $false
        Debug = $false
        ErrorAction = 'Stop'
    } + $script:UseBasic

    $zone,$recs = Find-SpaceshipRecords $RecordName $restParams
    Write-Debug "Found $zone and $($recs.Count) records"

    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    if ($recShort -eq '') { $recShort = '@' }

    $rec = $recs | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $recShort -and
        $_.value -eq $TxtValue
    }

    if ($rec) {
        $delParams = $restParams + @{
            Uri = 'https://spaceship.dev/api/v1/dns/records/{0}' -f $zone
            Method = 'DELETE'
            ContentType = 'application/json'
            Body = ConvertTo-Json @(
                @{
                    type = 'TXT'
                    name = $recShort
                    value = $TxtValue
                }
            ) -Compress
        }
        Write-Verbose "Removing the TXT record for $RecordName with value $TxtValue"
        Write-Debug "DELETE $($delParams.Uri)`n$($delParams.Body)"
        Invoke-RestMethod @delParams
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }



    <#
    .SYNOPSIS
        Remove a DNS TXT record from Spaceship

    .DESCRIPTION
        Remove a DNS TXT record from Spaceship

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SpaceshipCredential
        A PSCredential object containing the API key and secret for authenticating to the Spaceship API. The API key should be entered as the username and the API secret should be entered as the password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' (Get-Credential)

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

# https://docs.spaceship.dev/

function Find-SpaceshipRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$CommonRestParams
    )

    # setup a module variable to cache the record to zone mapping
    if (!$script:SpaceshipRecordZones) { $script:SpaceshipRecordZones = @{} }

    # check for the record in the cache
    if ($script:SpaceshipRecordZones.ContainsKey($RecordName)) {
        $zone = $script:SpaceshipRecordZones.$RecordName
    }

    if (-not $zone) {
        # try to find the zone from the record name by checking each parent domain for records until we find a match
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {
            $zoneCheck = ($pieces[$i..($pieces.Count-1)] -join '.')
            try {
                $records = Get-SpaceshipRecords $zoneCheck $CommonRestParams
                $zone = $zoneCheck
                $script:SpaceshipRecordZones.$RecordName = $zoneCheck
                break
            } catch {
                Write-Debug "Failed to get records for zone $($zoneCheck): $_"
            }
        }
    } else {
        $records = Get-SpaceshipRecords $zone $CommonRestParams
    }

    if (-not $zone) {
        throw "Unable to find zone for record $RecordName"
    }

    return $zone,$records
}

function Get-SpaceshipRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Zone,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$CommonRestParams
    )

    $uri = 'https://spaceship.dev/api/v1/dns/records/{0}' -f $Zone

    $take = 500
    $skip = 0
    $fetched = 0

    $allRecords = do {
        $restParams = $CommonRestParams + @{
            Uri = $uri
            Method = 'GET'
            Body = @{
                take = $take
                skip = $skip
            }
        }
        Write-Debug "GET $($restParams.Uri)`n$($restParams.Body | ConvertTo-Json -Compress)"
        $resp = Invoke-RestMethod @restParams

        $resp.items
        $fetched += $resp.items.Count
        $skip += $take
    } while ($fetched -lt $resp.total)

    return $allRecords
}
