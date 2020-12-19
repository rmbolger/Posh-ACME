function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [securestring]$HDEToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the token to plain text
    $HDETokenInsecure = [pscredential]::new('a',$HDEToken).GetNetworkCredential().Password

    # find the zone for the record
    $zoneConfig = Find-HDEZoneConfig $RecordName $HDETokenInsecure

    # get the record if it exists
    $rec = Get-HDETxtRecord $RecordName $TxtValue $zoneConfig.id $HDETokenInsecure

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    } else {

        # build the body to create the record
        $body = @{
            authToken = $HDETokenInsecure
            zoneConfig = $zoneConfig
            recordsToAdd = @(
                @{
                    name = $RecordName
                    type = 'TXT'
                    content = "`"$TxtValue`""
                    ttl = 60
                }
            )
        }

        Invoke-HDEZoneUpdate $body

    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hosting.de

    .DESCRIPTION
        Description for Hosting.de

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HDEToken
        Your Hosting.de API token as a SecureString value.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HDEToken (Read-Host -AsSecureString)

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
        [securestring]$HDEToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the token to plain text
    $HDETokenInsecure = [pscredential]::new('a',$HDEToken).GetNetworkCredential().Password

    # find the zone for the record
    $zoneConfig = Find-HDEZoneConfig $RecordName $HDETokenInsecure

    # get the record if it exists
    $rec = Get-HDETxtRecord $RecordName $TxtValue $zoneConfig.id $HDETokenInsecure

    if ($rec) {

        # build the body to remove the record
        $body = @{
            authToken = $HDETokenInsecure
            zoneConfig = $zoneConfig
            recordsToDelete = @(
                @{
                    id = $rec.id
                }
            )
        }

        Invoke-HDEZoneUpdate $body

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Hosting.de

    .DESCRIPTION
        Description for Hosting.de

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HDEToken
        Your Hosting.de API token as a SecureString value.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HDEToken (Read-Host -AsSecureString)

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
# https://www.hosting.de/api

function Find-HDEZoneConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$HDETokenInsecure
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:HDERecordZones) { $script:HDERecordZones = @{} }

    # check for the record in the cache
    if ($script:HDERecordZones.ContainsKey($RecordName)) {
        return $script:HDERecordZones.$RecordName
    }

    # create the base body with our auth token
    $body = @{authToken = $HDETokenInsecure}

    # Find the closest/deepest sub-zone that would hold the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        $body.filter = @{field='ZoneName';value=$zoneTest}
        $bodyJson = $body | ConvertTo-Json -Depth 10
        $bodySanitized = $bodyJson.Replace($body.authToken,'XXXXXXXX')

        $queryParams = @{
            Uri = 'https://secure.hosting.de/api/dns/v1/json/zoneConfigsFind'
            Method = 'POST'
            ContentType = 'application/json'
            Body = $bodyJson
            ErrorAction = 'Stop'
            Verbose = $false
        }

        try {
            Write-Debug "POST $($queryParams.Uri)`n$bodySanitized"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch { throw }

        if ($response.response -and $response.response.data.Count -gt 0) {
            $script:HDERecordZones.$RecordName = $response.response.data[0]
            return $script:HDERecordZones.$RecordName
        }
    }

    return $null

}

function Get-HDETxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZoneID,
        [Parameter(Mandatory,Position=3)]
        [string]$HDETokenInsecure
    )

    # create the search body
    $body = @{
        authToken = $HDETokenInsecure
        filter = @{
            subFilterConnective = 'AND'
            subFilter = @(
                @{ field = 'ZoneConfigId'; value = $ZoneID }
                @{ field = 'RecordName'; value = $RecordName }
                @{ field = 'RecordType'; value = 'TXT' }
                @{ field = 'RecordContent'; value = "`"$TxtValue`"" }
            )
        }
    }
    $bodyJson = $body | ConvertTo-Json -Depth 10
    $bodySanitized = $bodyJson.Replace($body.authToken,'XXXXXXXX')

    # create the query params
    $queryParams = @{
        Uri = 'https://secure.hosting.de/api/dns/v1/json/recordsFind'
        Method = 'POST'
        ContentType = 'application/json'
        Body = $bodyJson
        ErrorAction = 'Stop'
        Verbose = $false
    }

    try {
        Write-Debug "POST $($queryParams.Uri)`n$bodySanitized"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch { throw }

    if ($response.response -and $response.response.data.Count -gt 0) {
        return $response.response.data[0]
    }

}

function Invoke-HDEZoneUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$UpdateBody
    )

    $bodyJson = $UpdateBody | ConvertTo-Json -Depth 10
    $bodySanitized = $bodyJson.Replace($UpdateBody.authToken, 'XXXXXXXX')

    $queryParams = @{
        Uri = 'https://secure.hosting.de/api/dns/v1/json/zoneUpdate'
        Method = 'POST'
        ContentType = 'application/json'
        Body = $bodyJson
        ErrorAction = 'Stop'
        Verbose = $false
    }

    # zone modifications are technically asynchronus and additional edits are "blocked"
    # until the previous one is complete. So we'll setup a retry loop while we wait to
    # be unblocked.
    $response = $null
    $tries = 0

    for ($tries = 0; $tries -lt 13; $tries++) {
        try {
            Write-Debug "POST $($queryParams.Uri)`n$bodySanitized"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch { throw }

        if ($response.status -eq 'error' -and $response.errors[0].value -eq 'blocked') {
            Write-Verbose "Zone update blocked by another update. Sleeping for 5 seconds and retrying."
            Start-Sleep -Seconds 5
        } else {
            break
        }
    }

    # report on final errors if there were any
    if ($response.errors.Count -gt 0) {
        Write-Verbose "Last error:`n$($response.errors | ConvertTo-Json -Dep 10)"
        throw "Failed to update zone. See verbose output for details."
    }

}
