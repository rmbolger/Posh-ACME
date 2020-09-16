function Add-DnsTxtDOcean {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DOToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://api.digitalocean.com/v2/domains"
    $restParams = @{Headers=@{Authorization="Bearer $DOToken"};ContentType='application/json'}

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneName = Find-DOZone $apiRoot $restParams)) {
        throw "Unable to find Digital Ocean hosted zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    $recRoot = "$apiRoot/$zoneName/records"

    # query the current text record
    try {
        $rec = (Invoke-RestMethod $recRoot @restParams @script:UseBasic).domain_records |
                Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort -and $_.data -eq $TxtValue }
    } catch { throw }

    if (!$rec) {
        # create new
        $recBody = @{
            type = 'TXT';
            name = $recShort;
            data = $TxtValue;
            ttl  = 30;
        } | ConvertTo-Json
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Invoke-RestMethod $recRoot -Method Post @restParams -Body $recBody @script:UseBasic | Out-Null
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Digital Ocean DNS

    .DESCRIPTION
        Add a DNS TXT record to Digital Ocean DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DOToken
        A Personal Access Token generated on the Digital Ocean website with Write access.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtDOcean '_acme-challenge.site1.example.com' 'asdfqwer12345678' -DOToken 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtDOcean {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DOToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://api.digitalocean.com/v2/domains"
    $restParams = @{Headers=@{Authorization="Bearer $DOToken"};ContentType='application/json'}

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneName = Find-DOZone $apiRoot $restParams)) {
        throw "Unable to find Digital Ocean hosted zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    $recRoot = "$apiRoot/$zoneName/records"

    # query the current text record
    try {
        $rec = (Invoke-RestMethod $recRoot @restParams @script:UseBasic).domain_records |
                Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort -and $_.data -eq $TxtValue }
    } catch { throw }

    if ($rec) {
        # delete it
        Write-Verbose "Deleting $RecordName with value $TxtValue"
        Invoke-RestMethod "$recRoot/$($rec.id)" -Method Delete @restParams @script:UseBasic | Out-Null
    } else {
        # nothing to do
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Digital Ocean DNS

    .DESCRIPTION
        Remove a DNS TXT record from Digital Ocean DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DOToken
        A Personal Access Token generated on the Digital Ocean website with Write access.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtDOcean '_acme-challenge.site1.example.com' 'asdfqwer12345678' -DOToken 'xxxxxxxxxxxx'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtDOcean {
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
# https://developers.digitalocean.com/documentation/v2/#introduction

function Find-DOZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ApiRoot,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DORecordZones) { $script:DORecordZones = @{} }

    # check for the record in the cache
    if ($script:DORecordZones.ContainsKey($RecordName)) {
        return $script:DORecordZones.$RecordName
    }

    try {
        $zones = (Invoke-RestMethod "$ApiRoot" @RestParams @script:UseBasic).domains
    } catch { throw }

    # Since Digital Ocean could be hosting both apex and sub-zones, we need to find the closest/deepest
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
        if ($zoneTest -in $zones.name) {
            $script:DORecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }

    return $null
}
