function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ConstellixKey,
        [Parameter(Mandatory,Position=3)]
        [securestring]$ConstellixSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure secret to a normal string
    $ConstellixSecretInsecure = [pscredential]::new('a',$ConstellixSecret).GetNetworkCredential().Password

    $apiBase = 'https://api.dns.constellix.com/v1/domains'

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneID,$zoneName = Find-ConstellixZone $RecordName $ConstellixKey $ConstellixSecretInsecure $apiBase
    if (-not $zoneID) {
        throw "Unable to find Constellix hosted zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''

    # check for an existing record
    $rec = Get-ConstellixTXTRecord $recShort $zoneID $ConstellixKey $ConstellixSecretInsecure $apiBase

    # Constellix stores records with multiple values in a single record object that shares an ID value
    # For TXT records specifically, each value is in an array on the roundRobin property and "quoted"
    if ($rec -and "`"$TxtValue`"" -in $rec.roundRobin.value) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    } else {

        $auth = Get-ConstellixAuthHeader $ConstellixKey $ConstellixSecretInsecure

        if (-not $rec) {
            # new record
            $queryParams = @{
                Uri = "$ApiBase/$zoneID/records/txt"
                Method = 'POST'
                Body = @{
                    name = $recShort
                    ttl = '60'
                    roundRobin = @(@{value="`"$TxtValue`""})
                } | ConvertTo-Json -Depth 5
                Headers = $auth
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "POST $($queryParams.Uri)"
            Write-Debug "Body:`n$($queryParams.Body)"
            Write-Verbose "Creating new TXT record for $RecordName with value $TxtValue."
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null

        } else {
            # new value on existing record
            $rec.roundRobin += @{value="`"$TxtValue`""}
            $queryParams = @{
                Uri = "$ApiBase/$zoneID/records/txt/$($rec.id)"
                Method = 'PUT'
                Body = @{
                    name = $recShort
                    ttl = '60'
                    roundRobin = $rec.roundRobin
                } | ConvertTo-Json -Depth 5
                Headers = $auth
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "PUT $($queryParams.Uri)"
            Write-Debug "Body:`n$($queryParams.Body)"
            Write-Verbose "Adding value $TxtValue to TXT record for $RecordName."
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Constellix.

    .DESCRIPTION
        Add a DNS TXT record to Constellix.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ConstellixKey
        The Constellix API key for your account.

    .PARAMETER ConstellixSecret
        The Constellix API secret key for your account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "Constellix Secret" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key' $secret

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
        [string]$ConstellixKey,
        [Parameter(Mandatory,Position=3)]
        [securestring]$ConstellixSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure secret to a normal string
    $ConstellixSecretInsecure = [pscredential]::new('a',$ConstellixSecret).GetNetworkCredential().Password

    $apiBase = 'https://api.dns.constellix.com/v1/domains'

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneID,$zoneName = Find-ConstellixZone $RecordName $ConstellixKey $ConstellixSecretInsecure $apiBase
    if (-not $zoneID) {
        throw "Unable to find Constellix hosted zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''

    # check for an existing record
    $rec = Get-ConstellixTXTRecord $recShort $zoneID $ConstellixKey $ConstellixSecretInsecure $apiBase

    # Constellix stores records with multiple values in a single record object that shares an ID value
    # For TXT records specifically, each value is in an array on the roundRobin property and "quoted"
    if ($rec -and "`"$TxtValue`"" -in $rec.roundRobin.value) {

        $auth = Get-ConstellixAuthHeader $ConstellixKey $ConstellixSecretInsecure

        if ($rec.roundRobin.Count -gt 1) {
            # remove the value from the list
            $rec.roundRobin = @($rec.roundRobin | Where-Object { $_.value -ne "`"$TxtValue`"" })
            $queryParams = @{
                Uri = "$ApiBase/$zoneID/records/txt/$($rec.id)"
                Method = 'PUT'
                Body = @{
                    name = $recShort
                    ttl = '60'
                    roundRobin = $rec.roundRobin
                } | ConvertTo-Json -Depth 5
                Headers = $auth
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "PUT $($queryParams.Uri)"
            Write-Debug "Body:`n$($queryParams.Body)"
            Write-Verbose "Removing value $TxtValue from TXT record for $RecordName."
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null

        } else {
            # delete the record since it's the last one
            $queryParams = @{
                Uri = "$ApiBase/$zoneID/records/txt/$($rec.id)"
                Method = 'DELETE'
                Headers = $auth
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "DELETE $($queryParams.Uri)"
            Write-Verbose "Deleting TXT record for $RecordName."
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Constellix.

    .DESCRIPTION
        Remove a DNS TXT record from Constellix.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ConstellixKey
        The Constellix API key for your account.

    .PARAMETER ConstellixSecret
        The Constellix API secret key for your account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "Constellix Secret" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key' $secret

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
# https://api-docs.constellix.com/

function Get-ConstellixAuthHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ConstellixKey,
        [Parameter(Mandatory,Position=1)]
        [string]$ConstellixSecretInsecure
    )

    # https://api-docs.constellix.com/#0995bc8a-97a0-414e-82da-2788ed30ea21

    # We need to initialize an HMACSHA1 instance with the secret key as a byte array.
    $secBytes = [Text.Encoding]::UTF8.GetBytes($ConstellixSecretInsecure)
    $hmac = New-Object Security.Cryptography.HMACSHA1($secBytes,$true)

    # We need to hash a Unix timestamp and base64 encode it
    $reqTime = (Get-DateTimeOffsetNow).ToUnixTimeMilliseconds().ToString()
    $timeBytes = [Text.Encoding]::UTF8.GetBytes($reqTime)
    $timeHash = [Convert]::ToBase64String($hmac.ComputeHash($timeBytes))

    # now build the header hashtable
    Write-Debug "Key: $ConstellixKey, Date: $reqTime, Hash: $timeHash"
    $header = @{
        'x-cns-security-token' = "{0}:{1}:{2}" -f $ConstellixKey,$timeHash,$reqTime
    }

    return $header
}

function Find-ConstellixZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ConstellixKey,
        [Parameter(Mandatory,Position=2)]
        [string]$ConstellixSecretInsecure,
        [Parameter(Mandatory,Position=3)]
        [string]$ApiBase
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:ConstellixRecordZones) { $script:ConstellixRecordZones = @{} }

    # check for the record in the cache
    if ($script:ConstellixRecordZones.ContainsKey($RecordName)) {
        return $script:ConstellixRecordZones.$RecordName
    }

    $auth = Get-ConstellixAuthHeader $ConstellixKey $ConstellixSecretInsecure

    # Find the closest/deepest sub-zone that would hold the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        try {
            $queryParams = @{
                Uri = "$ApiBase/search?exact=$zoneTest"
                Headers = $auth
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "GET $($queryParams.Uri)"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch {
            # 404 responses mean the zone wasn't found, so skip to the next check
            if (404 -eq $_.Exception.Response.StatusCode) {
                continue
            }
            # re-throw anything else
            throw
        }

        if ($response) {
            $script:ConstellixRecordZones.$RecordName = $response.id,$response.name
            return $response.id,$response.name
        }
    }

    return $null
}

function Get-ConstellixTXTRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordShort,
        [Parameter(Mandatory,Position=1)]
        [int]$ZoneID,
        [Parameter(Mandatory,Position=2)]
        [string]$ConstellixKey,
        [Parameter(Mandatory,Position=3)]
        [string]$ConstellixSecretInsecure,
        [Parameter(Mandatory,Position=4)]
        [string]$ApiBase
    )

    # Annoyingly, this is a two call process. First we search for the record ID.
    # Then we use the ID to get the record data.

    $auth = Get-ConstellixAuthHeader $ConstellixKey $ConstellixSecretInsecure

    try {
        # search for the record by name
        $queryParams = @{
            Uri = "$ApiBase/$ZoneID/records/txt/search?exact=$RecordShort"
            Headers = $auth
            ContentType = 'application/json'
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "GET $($queryParams.Uri)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch {
        # Re-throw any error but a 404 (not found)
        if (404 -ne $_.Exception.Response.StatusCode) {
            throw
        }
    }

    if (-not $response -or -not $response.id) { return $null }

    try {
        # use the record ID to get the details
        $queryParams = @{
            Uri = "$ApiBase/$ZoneID/records/txt/$($response.id)"
            Headers = $auth
            ContentType = 'application/json'
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "GET $($queryParams.Uri)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch {
        Write-Warning "Unexpected error querying record $($response.id) details from Constellix: $($_.Exception.Message)"
    }

    return $response
}
