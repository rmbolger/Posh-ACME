function Add-DnsTxtPointDNS {
    [CmdLetBinding(DefaultParameterSetName='Secure')]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$PDUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$PDKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$PDKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $headers = Get-PDAuthHeaders @PSBoundParameters

    $zone = Find-PDZone $RecordName $headers

    if ($null -eq $zone) {
        throw "Cannot find PointDNS hosted zone for $RecordName"
    }

    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')
        $records = Get-PDZoneRecords $zone.id "TXT" $recShort $headers
    } catch { throw }

    $data = @( $records | ForEach-Object { $_.zone_record.data -replace '"','' } )

    if ($records.Count -eq 0 -or $TxtValue -notin $data) {
        try {
            Write-Verbose "Adding record $RecordName with TXT value $TxtValue"
            Add-PDZoneRecord $zone.id "TXT" $recShort $TxtValue $headers
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to PointDNS.

    .DESCRIPTION
        Uses the PointDNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PDUser
        PointDNS Username / Email

    .PARAMETER PDKey
        PointDNS API key. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER PDKeyInsecure
        PointDNS API key. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtPointDNS '_acme-challenge.example.com' 'txt-value' 'user@example.com' 'key-value'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtPointDNS {
    [CmdLetBinding(DefaultParameterSetName='Secure')]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$PDUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$PDKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$PDKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $headers = Get-PDAuthHeaders @PSBoundParameters

    $zone = Find-PDZone $RecordName $headers

    if ($null -eq $zone) {
        throw "Cannot find PointDNS hosted zone for $RecordName"
    }

    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')
        $records = Get-PDZoneRecords $zone.id "TXT" $recShort $headers
    } catch { throw }

    $data = @( $records | ForEach-Object { $_.zone_record.data -replace '"','' } )

    if ($records.Count -eq 0 -or $TxtValue -notin $data) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $record = ($records | Where-Object { $_.zone_record.data -replace '"','' -eq $TxtValue})
            Remove-PDZoneRecord $zone.id $record.zone_record.id $headers
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from PointDNS.

    .DESCRIPTION
        Uses the PointDNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PDUser
        PointDNS Username / Email

    .PARAMETER PDKey
        PointDNS API key. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER PDKeyInsecure
        PointDNS API key. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtPointDNS '_acme-challenge.example.com' 'txt-value' 'user@example.com' 'key-value'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtPointDNS {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

##################################
# Helper Functions
##################################
function Add-PDZoneRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ZoneId,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordType,
        [Parameter(Mandatory,Position=2)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=3)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=4)]
        [hashtable]$Headers
    )

    $apiBase = "https://api.pointhq.com/zones/$ZoneId/records"

    $payload = @{
        'zone_record' = @{
            'name' = $RecordName
            'record_type' = $RecordType
            'data' = $TxtValue
            'ttl' = 3600
        }
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $apiBase -Headers $Headers -Method Post `
            -ContentType 'application/json' -Body $payload `
            -EA Stop @script:UseBasic | Out-Null
    } catch { throw }
}

function Find-PDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$Headers
    )

    if (!$script:PointDNSZones) { $script:PointDNSZones = @{} }

    if ($script:PointDNSZones.ContainsKey($RecordName)) {
        return $script:PointDNSZones.$RecordName
    }

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zone = $pieces[$i..($pieces.Count-1)] -join '.'
        $response = Get-PDZone $zone $Headers

        if ($null -ne $response) {
            $script:PointDNSZones.$RecordName = $response
            return $response
        }
    }

    return $null
}

function Get-PDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$Headers
    )

    $apiBase = "https://api.pointhq.com/zones"

    try {
        $response = Invoke-RestMethod -Uri $apiBase -Headers $Headers `
            -Method Get -EA Stop @script:UseBasic
    } catch { throw }

    foreach ($zone in $response.zone) {
        if ($zone.name -eq $RecordName) {
            return $zone
        }
    }

    return $null
}

function Get-PDZoneRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ZoneId,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordType,
        [Parameter(Mandatory,Position=2)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=3)]
        [hashtable]$Headers
    )

    $uri = "https://api.pointhq.com/zones/$ZoneId/records/?record_type=$RecordType&record_name=$RecordName"

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers `
            -Method Get -EA Stop @script:UseBasic
    } catch { throw }

    if ($null -ne $response) {
        return $response
    }
    return $null
}

function Get-PDAuthHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$User,
        [Parameter(Mandatory,Position=1)]
        [string]$Token
    )

    $encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(
        "$($User):$($Token)"))

    return "Basic $encodedCredentials"
}

function Get-PDAuthHeaders {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$PDUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=1)]
        [securestring]$PDKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=1)]
        [string]$PDKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $PDKeyInsecure = (New-Object pscredential "user",$PDKey).GetNetworkCredential().Password
    }

    $authHeader = Get-PDAuthHeader $PDUser $PDKeyInsecure
    $headers = @{ 'Authorization' = $authHeader }

    return $headers
}

function Remove-PDZoneRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ZoneId,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordId,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$Headers
    )

    $uri = "https://api.pointhq.com/zones/$ZoneId/records/$RecordId"

    try {
        Invoke-RestMethod -Uri $uri -Headers $Headers `
            -Method Delete -EA Stop @script:UseBasic | Out-Null
    } catch { throw }
}
