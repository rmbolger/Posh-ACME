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
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$HetznerTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://dns.hetzner.com/api/v1'

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HetznerTokenInsecure = (New-Object PSCredential "user",$HetznerToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            'Auth-API-Token' = $HetznerTokenInsecure
            Accept = 'application/json'
        }
        ContentType = 'application/json'
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-HetznerZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $recs = Invoke-RestMethod "$apiRoot/records?zone_id=$($zone.id)" `
            @restParams @Script:UseBasic -EA Stop
    } catch { throw }

    # check for a matching record
    $rec = $recs.records | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $recShort -and
        $_.value -eq $TxtValue
    }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # create request body schema
        $body = @{
            name = $recShort
            ttl = 600
            type = 'TXT'
            value = $TxtValue
            zone_id = $zone.id
        }
        $json = $body | ConvertTo-Json

        try {
            Write-Verbose "Add Record $RecordName with value $TxtValue."

            Invoke-RestMethod "$apiRoot/records" -Method Post -Body $json `
                @restParams @Script:UseBasic -EA Stop | Out-Null
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
        The API token for your Hetzner account. This SecureString version can only be used on Windows or any OS running PowerShell 6.2 or later.
    .PARAMETER HetznerTokenInsecure
        The API token for your Hetzner account. This standard String version may be used on any OS.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HetznerTokenInsecure 'xxxxxxxx'
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
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$HetznerTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://dns.hetzner.com/api/v1'

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HetznerTokenInsecure = (New-Object PSCredential "user",$HetznerToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            'Auth-API-Token' = $HetznerTokenInsecure
            Accept = 'application/json'
        }
        ContentType = 'application/json'
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-HetznerZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $recs = Invoke-RestMethod "$apiRoot/records?zone_id=$($zone.id)" `
            @restParams @Script:UseBasic -EA Stop
    } catch { throw }

    # check for a matching record
    $rec = $recs.records | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $recShort -and
        $_.value -eq $TxtValue
    }

    if ($rec) {
        try {
            Write-Verbose "Remove Record $RecordName ($($rec.Id)) with value $TxtValue."
            Invoke-RestMethod "$apiRoot/records/$($rec.Id)" -Method Delete `
               @restParams @Script:UseBasic -EA Stop | Out-Null
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
        The API token for your Hetzner account. This SecureString version can only be used on Windows or any OS running PowerShell 6.2 or later.
    .PARAMETER HetznerTokenInsecure
        The API token for your Hetzner account. This standard String version may be used on any OS.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HetznerTokenInsecure 'xxxxxxxx'
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

    # first, get all Zones, Zone to get is identified by 'ZoneID'.
    try {
        $response = Invoke-RestMethod -Uri "https://dns.hetzner.com/api/v1/zones" `
            @RestParameters @Script:UseBasic -EA Stop
    } catch { throw }

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

        $zone = $response.zones | Select-Object id,name |
            Where-Object { $_.name -eq $zoneTest }

        if ($zone) {
            Write-Debug "Zone $zoneTest found."
            $script:HetznerRecordZones.$RecordName = $zone
            return $zone
        } else {
            Write-Debug "Zone $zoneTest does not exist ..."
        }
    }

    return $null
}
