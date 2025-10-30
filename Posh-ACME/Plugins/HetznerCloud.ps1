function Get-CurrentPluginType { 'dns-01' }

Function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$HetznerToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$HetznerTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HetznerTokenInsecure = [pscredential]::new('a',$HetznerToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            Authorization = "Bearer $HetznerTokenInsecure"
            Accept = 'application/json'
        }
        ContentType = 'application/json'
        Verbose = $false
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-HetznerZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.name.TrimEnd('.')))$",''

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $query = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets?type=TXT&name=$recShort"
        Write-Debug "GET $query"
        $recs = Invoke-RestMethod $query @restParams @Script:UseBasic -EA Stop
    } catch {
        if (404 -ne $_.Exception.Response.StatusCode) {
            throw 
        }
    }

    # check for a matching record
    $rec = $recs.rrsets | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $recShort
    }

    if ($rec -And $rec.value -eq $TxtValue) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        if ($rec) {
            Write-Debug "Record $RecordName exists with wrong $TxtValue. Removing old record."
		    Remove-DnsTxt $RecordName, $TxtValue, $HetznerToken, $HetznerTokenInsecure, $ExtraParams
        }
        
        $queryParams = @{
            Uri = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets"
            Method = 'POST'
            Body = @{
                name = $recShort
                type = 'TXT'
                ttl = 600
                records = @(@{
                    value = """$TxtValue"""
                    comment = "Lets encrypt"
                })
            } | ConvertTo-Json
            ErrorAction = 'Stop'
        }

        try {
            Write-Verbose "Add Record $RecordName with value $TxtValue."
            Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
            Invoke-RestMethod @queryParams @restParams @Script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hetzner.
    .DESCRIPTION
        Uses the Hetzner DNS API to add or update a DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER HetznerToken
        The API token for your Hetzner account.
    .PARAMETER HetznerTokenInsecure
        (DEPRECATED) The API token for your Hetzner account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HetznerToken $token

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
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$HetznerToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$HetznerTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HetznerTokenInsecure = [pscredential]::new('a',$HetznerToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            Authorization = "Bearer $HetznerTokenInsecure"
            Accept = 'application/json'
        }
        ContentType = 'application/json'
        Verbose = $false
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-HetznerZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.name.TrimEnd('.')))$",''

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $query = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets?type=TXT&name=$recShort"
        Write-Debug "GET $query"
        $recs = Invoke-RestMethod $query @restParams @Script:UseBasic -EA Stop
    } catch { throw }

    # check for a matching record
    $rec = $recs.rrsets | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $recShort
    }

    if ($rec) {
        try {
            Write-Verbose "Remove Record $RecordName ($($rec.Id)) with value $TxtValue."
            $query = "https://api.hetzner.cloud/v1/zones/$($zone.id)/rrsets/$recShort/TXT"
            Write-Debug "DELETE $query"
            Invoke-RestMethod $query -Method Delete @restParams @Script:UseBasic -EA Stop | Out-Null
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
    .PARAMETER HetznerToken
        The API token for your Hetzner account.
    .PARAMETER HetznerTokenInsecure
        (DEPRECATED) The API token for your Hetzner account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HetznerToken $token

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

# API Docs: https://dns.hetzner.com/api-docs/

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
    if (!$script:HetznerRecordZones) { $script:HetznerRecordZones = @{} }

    # check for the record in the cache
    if ($script:HetznerRecordZones.ContainsKey($RecordName)) {
        Write-Debug "Result from Cache $($script:HetznerRecordZones.$RecordName.Name)"
        return $script:HetznerRecordZones.$RecordName
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
            $response = Invoke-RestMethod $query @RestParameters @Script:UseBasic -EA Stop
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

        $script:HetznerRecordZones.$RecordName = $zone
        return $zone
    }

    return $null
}
