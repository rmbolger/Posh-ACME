function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$ApiKey,
        [Parameter(ParameterSetName='ClearText',Mandatory,Position=2)]
        [string]$ApiKeyClearText,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # if secure - grab cleartext
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $ApiKeyClearText = [pscredential]::new('a',$ApiKey).GetNetworkCredential().Password
    }

    $apiRoot = "https://api.ukfast.io/safedns/v1"
    
    $restParams = @{
        Headers = @{
            Accept = 'application/json'
            Authorization = $ApiKeyClearText
        }
        ContentType = 'application/json'
    }

    # find the closest zone for our record
    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneName = Find-UKFastZone $RecordName $apiRoot $restParams
    if (!$zoneName) {
        throw "Unable to find UKFast SafeDNS zone for $RecordName"
    }

    $recRoot = "$apiRoot/zones/$zoneName/records"

    try {
        $rec = (Invoke-RestMethod $recRoot @restParams -UseBasicParsing).Data |
                Where-Object { $_.type -eq 'TXT' -and $_.name -eq $RecordName -and $_.content -eq '"'+$TxtValue+'"' }
    }
    catch { throw }

    if (!$rec) {
        #create new

        $recBody = @{
            type = 'TXT'
            name = $RecordName
            content = '"' + $TxtValue + '"'
            ttl = 60
        } | ConvertTo-Json
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Invoke-RestMethod $recRoot -Method Post @restParams -Body $recBody -UseBasicParsing | Out-Null
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to UKFast SafeDNS

    .DESCRIPTION
        Add a DNS TXT record to UKFast SafeDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ApiKey
        An API Application Key generated on the UKFast website with Read/Write access. SecureString version.

    .PARAMETER ApiKeyClearText
        An API Application Key generated on the UKFast website with Read/Write access. String version.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -ApiKey $key

        Adds a TXT record for the specified site with the specified value. Key passed in as securestring.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -ApiKeyClearText "API_KEY"

        Adds a TXT record for the specified site with the specified value. Key passed in as clear text value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$ApiKey,
        [Parameter(ParameterSetName='ClearText',Mandatory,Position=2)]
        [string]$ApiKeyClearText,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # if secure - grab cleartext
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $ApiKeyClearText = [pscredential]::new('a',$ApiKey).GetNetworkCredential().Password
    }

    $apiRoot = "https://api.ukfast.io/safedns/v1"
    
    $restParams = @{
        Headers = @{
            Accept = 'application/json'
            Authorization = $ApiKeyClearText
        }
        ContentType = 'application/json'
    }

    # find the closest zone for our record
    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneName = Find-UKFastZone $RecordName $apiRoot $restParams
    if (!$zoneName) {
        throw "Unable to find UKFast SafeDNS zone for $RecordName"
    }

    $recRoot = "$apiRoot/zones/$zoneName/records"

    try {
        $rec = (Invoke-RestMethod $recRoot @restParams -UseBasicParsing).Data |
                Where-Object { $_.type -eq 'TXT' -and $_.name -eq $RecordName -and ($_.content -eq '"'+$TxtValue+'"')}
    }
    catch { throw }

    if ($rec) {
        #if record exists, delete it
        Write-Verbose "Deleting $RecordName with value $TxtValue"
        Invoke-RestMethod "$recRoot/$($rec.id)" -Method Delete @restParams -UseBasicParsing | Out-Null
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from UKFast SafeDNS 

    .DESCRIPTION
        Remove a DNS TXT record from UKFast SafeDNS 

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ApiKey
        An API Application Key generated on the UKFast website with Read/Write access. SecureString version.

    .PARAMETER ApiKeyClearText
        An API Application Key generated on the UKFast website with Read/Write access. String version.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -ApiKey $key

        Removes a TXT record for the specified site with the specified value. Key passed in as securestring.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -ApiKeyClearText "API_KEY"

        Removes a TXT record for the specified site with the specified value. Key passed in as clear text value.
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
# https://developers.ukfast.io/documentation/safedns

function Find-UKFastZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ApiRoot,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:UKFastRecordZones) { $script:UKFastRecordZones = @{} }

    # check for the record in the cache
    if ($script:UKFastRecordZones.ContainsKey($RecordName)) {
        return $script:UKFastRecordZones.$RecordName
    }

    try {
        $zones = (Invoke-RestMethod "$ApiRoot/zones" @RestParams -UseBasicParsing).Data
    } catch { throw }

    # Since UKFast could be hosting both apex and sub-zones, we need to find the closest/deepest
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
            $script:UKFastRecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }

    return $null
}
