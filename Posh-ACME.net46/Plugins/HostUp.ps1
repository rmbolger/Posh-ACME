function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$HUToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Gets the plaintext version of the token
    $HUTokenInsecure = [pscredential]::new('a', $HUToken).GetNetworkCredential().Password

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    $apiRoot = 'https://cloud.hostup.se/api'

    $commonParams = @{
        Headers     = @{ "X-API-Key" = $HUTokenInsecure }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose     = $false
        Debug       = $false
    } + $script:UseBasic

    $zone = Find-HostUpZone -RecordName $RecordName -CommonRestParams $commonParams

    if (-not $zone) {
        throw "Unable to find HostUp zone for $RecordName"
    }

    Write-Debug "Found zone $($zone.domain) for record $RecordName."

    $zoneRoot = "$apiRoot/dns/zones/$($zone.domain_id)"

    try {
        $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.domain.TrimEnd('.')))$", ''
        Write-Debug "GET $zoneRoot/records"

        $resp = Invoke-RestMethod -Uri "$zoneRoot/records" @commonParams

        Write-Debug "Response:`n$($resp | ConvertTo-Json -Depth 10)"
    }
    catch { throw }

    $record = $resp.data.zone.records |
    Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $RecordName -and
        $_.value -eq $TxtValue
    }

    if (-not $record) {
        try {
            Write-Verbose "Adding TXT record for $RecordName with value $TxtValue"

            $bodyJson = @{
                type  = "TXT"
                ttl   = 60
                name  = $recShort
                value = $TxtValue
            } | ConvertTo-Json -Compress

            Write-Debug "POST $zoneRoot/records`n$bodyJson"
            Invoke-RestMethod -Uri "$zoneRoot/records" -Method Post -Body $bodyJson @commonParams | Out-Null
        }
        catch { throw }
    }
    else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to HostUp

    .DESCRIPTION
        Description for HostUp

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HUToken
        The Account API token for HostUp.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "HostUp Token" -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$HUToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $HUTokenInsecure = [pscredential]::new('a', $HUToken).GetNetworkCredential().Password

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    $apiRoot = 'https://cloud.hostup.se/api'

    $commonParams = @{
        Headers     = @{ "X-API-Key" = $HUTokenInsecure }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose     = $false
        Debug       = $false
    } + $script:UseBasic

    $zone = Find-HostUpZone -RecordName $RecordName -CommonRestParams $commonParams

    if (-not $zone) {
        throw "Unable to find HostUp zone for $RecordName"
    }

    Write-Debug "Found zone $($zone.domain) for record $RecordName."

    $zoneRoot = "$apiRoot/dns/zones/$($zone.domain_id)"

    try {
        Write-Debug "GET $zoneRoot/records"

        $resp = Invoke-RestMethod -Uri "$zoneRoot/records" @commonParams
        Write-Debug "Response:`n$($resp | ConvertTo-Json -Depth 10)"
    }
    catch { throw }

    $record = $resp.data.zone.records |
    Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $RecordName -and
        $_.value -eq $TxtValue
    }

    if ($record) {
        try {
            $recordUri = "$zoneRoot/records/$($record.id)"

            Write-Debug "DELETE $recordUri"
            Write-Verbose "Deleting $RecordName with value $TxtValue"

            Invoke-RestMethod -Uri $recordUri -Method Delete @commonParams | Out-Null
        }
        catch { throw }
    }
    else {
        Write-Debug "Record $RecordName with value $TxtValue does not exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from HostUp

    .DESCRIPTION
        Description for HostUp

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HUToken
        The Account API token for HostUp.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "HostUp Token" -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # This method is not used for HostUp

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
# https://developer.hostup.se/

function Find-HostUpZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$CommonRestParams
    )

    if (!$script:HURecordZones) { $script:HURecordZones = @{} }

    if ($script:HURecordZones.ContainsKey($RecordName)) {
        return $script:HURecordZones.$RecordName
    }

    $apiRoot = 'https://cloud.hostup.se/api'

    Write-Debug "Finding HostUp zone for $RecordName"

    try {
        $uri = "$apiRoot/dns/zones"
        Write-Debug "GET $uri"

        $resp = Invoke-RestMethod $uri @CommonRestParams

        Write-Debug "Response`n$($resp | ConvertTo-Json -Depth 10)"
        $zones = @($resp.data.zones)
    }
    catch { throw }

    $recordPieces = $RecordName.Split('.')
    for ( $i = 0; $i -lt ($recordPieces.Count - 1); $i++) {
        $zoneTest = $recordPieces[$i..($recordPieces.Count - 1)] -join '.'
        Write-Debug "Checking $zoneTest"

        foreach ($zone in $zones) {
            if ($zone.domain -eq $zoneTest) {
                $script:HURecordZones.$RecordName = $zone
                return $zone
            }
        }
    }

    return $null
}
