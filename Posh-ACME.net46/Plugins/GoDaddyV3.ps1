function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$GDPAT,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # The GoDaddy V3 API is only consumer facing as far as we know at the moment and doesn't
    # require a customer ID like the Brandsight/Corp v2 API.
    $apiRoot = "https://api.godaddy.com/v3/domains/zones"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v3/domains/zones"
    }

    # grab the plain text secret
    $GDSecret = [pscredential]::new('a',$GDPAT).GetNetworkCredential().Password

    # build the common parameters for all API calls
    $commonParams = @{
        Headers = @{
            Authorization = "Bearer $GDSecret"
        }
        ErrorAction = 'Stop'
        Verbose = $false
        Debug = $false
    } + $script:UseBasic

    if (-not ($zone = Find-GDZone $RecordName $commonParams $apiRoot)) {
        throw "Unable to find matching zone for $RecordName."
    }
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    if ($recShort -eq '') { $recShort = '@' }

    # Get a list of existing TXT records for this record name
    try {
        $queryParams = @{
            Uri = "$apiRoot/$zone/dns-records?type=TXT&name=$recShort"
        } + $commonParams
        Write-Debug "GET $($queryParams.Uri)"
        $recs = @(Invoke-RestMethod @queryParams | Select-Object -ExpandProperty items)
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        try {
            Write-Verbose "Adding a new TXT record for $RecordName with value $TxtValue"
            $queryParams = @{
                Uri = "$apiRoot/$zone/dns-records"
                Method = 'POST'
                Body = @{
                    type = 'TXT'
                    name = $recShort
                    data = $TxtValue
                    ttl = 600
                } | ConvertTo-Json -Compress
                ContentType = 'application/json'
            } + $commonParams
            Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
            Invoke-RestMethod @queryParams | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to GoDaddy.

    .DESCRIPTION
        Add a DNS TXT record to GoDaddy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDPAT
        The GoDaddy V3 Personal Access Token

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pat = Read-Host 'API PAT' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $pat

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$GDPAT,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # The GoDaddy V3 API is only consumer facing as far as we know at the moment and doesn't
    # require a customer ID like the Brandsight/Corp v2 API.
    $apiRoot = "https://api.godaddy.com/v3/domains/zones"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v3/domains/zones"
    }

    # grab the plain text secret
    $GDSecret = [pscredential]::new('a',$GDPAT).GetNetworkCredential().Password

    # build the common parameters for all API calls
    $commonParams = @{
        Headers = @{
            Authorization = "Bearer $GDSecret"
        }
        ErrorAction = 'Stop'
        Verbose = $false
        Debug = $false
    } + $script:UseBasic

    if (-not ($zone = Find-GDZone $RecordName $commonParams $apiRoot)) {
        throw "Unable to find matching zone for $RecordName."
    }
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    if ($recShort -eq '') { $recShort = '@' }

    # Get a list of existing TXT records for this record name
    try {
        $queryParams = @{
            Uri = "$apiRoot/$zone/dns-records?type=TXT&name=$recShort"
        } + $commonParams
        Write-Debug "GET $($queryParams.Uri)"
        $recs = @(Invoke-RestMethod @queryParams | Select-Object -ExpandProperty items)
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # grab the matching record ID
        $recId = $recs | Where-Object { $_.data -eq $TxtValue } | Select-Object -ExpandProperty recordId
        if (-not $recId) {
            throw "Unable to find record ID for $RecordName with value $TxtValue"
        }
        try {
            Write-Verbose "Removing a TXT record for $RecordName with value $TxtValue"
            $queryParams = @{
                Uri = "$apiRoot/$zone/dns-records/$recId"
                Method = 'DELETE'
            } + $commonParams
            Write-Debug "DELETE $($queryParams.Uri)"
            Invoke-RestMethod @queryParams | Out-Null
        } catch { throw }
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from GoDaddy.

    .DESCRIPTION
        Remove a DNS TXT record from GoDaddy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDPAT
        The GoDaddy V3 Personal Access Token

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pat = Read-Host 'API PAT' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $pat

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

# API Docs:
# https://developer.godaddy.com/en/docs/api-users

function Find-GDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$CommonParams,
        [Parameter(Mandatory, Position = 2)]
        [string]$ApiRoot
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GDRecordZones) { $script:GDRecordZones = @{} }

    # check for the record in the cache
    if ($script:GDRecordZones.ContainsKey($RecordName)) {
        return $script:GDRecordZones.$RecordName
    }

    # We need to find the closest/deepest sub-zone that would hold
    # the record rather than just adding it to the apex.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        # Even though GoDaddy doesn't officially support sub-zone DNS hosting, historically
        # it is possible to add a "domain" that is technically a sub-zone of an actual domain
        # registered elsewhere and just delegate to GoDaddy's nameservers. The web UI and API
        # won't list it as a domain in the normal domain list. But you can modify its records
        # if you know the zone name. We're going to search for the zone name by querying for
        # its NS records.

        try {
            $queryParams = @{
                Uri = "$ApiRoot/$zoneTest/dns-records?type=NS"
            } + $CommonParams
            Write-Debug "GET $($queryParams.Uri)"
            # no error means we found the zone
            Invoke-RestMethod @queryParams | Out-Null
        } catch {
            # The NS check may throw either a 404 (Not Found) or a 400 (BadRequest) when
            # the zone is not found. Ignore those and re-throw anything else
            if ($_.Exception.Response.StatusCode -notin 404,400) {
                throw
            }
            continue
        }

        $script:GDRecordZones.$RecordName = $zoneTest
        return $zoneTest
    }

    return $null
}
