function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DOTokenSecure,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$DOToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DOToken = [pscredential]::new('a',$DOTokenSecure).GetNetworkCredential().Password
    }

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

    .PARAMETER DOTokenSecure
        A Personal Access Token generated on the Digital Ocean website with Write access.

    .PARAMETER DOToken
        (DEPRECATED) A Personal Access Token generated on the Digital Ocean website with Write access.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DOTokenSecure,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$DOToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DOToken = [pscredential]::new('a',$DOTokenSecure).GetNetworkCredential().Password
    }

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

    .PARAMETER DOTokenSecure
        A Personal Access Token generated on the Digital Ocean website with Write access.

    .PARAMETER DOToken
        (DEPRECATED) A Personal Access Token generated on the Digital Ocean website with Write access.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
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
# https://docs.digitalocean.com/reference/api/api-reference/

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

    # gather all domains in the digital ocean account
    $zones = @()
    $responses = @()
    $request = $ApiRoot
    do {
        try {
            $responses += Invoke-RestMethod "$request" @RestParams @script:UseBasic
        } catch {
            throw
        }
        $zones += ($responses[-1]).domains
        $request = $responses[-1].links.pages.next
    } until (
        ($null -eq $request)
    )

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
