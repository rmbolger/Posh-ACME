function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$InfomaniakToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # dns-01 values arrive bare, but dns-persist-01 values arrive already wrapped in
    # double quotes because they contain spaces. The API stores exactly one pair of
    # quotes either way, so normalize the incoming value to the quoted form and compare
    # against the stored target as-is.
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = '"{0}"' -f $TxtValue
    }

    $apiRoot = 'https://api.infomaniak.com/2/zones'

    # grab the plain text token
    $tokenPlain = [pscredential]::new('a',$InfomaniakToken).GetNetworkCredential().Password

    # build the common parameters for all API calls
    $commonParams = @{
        Headers = @{
            Authorization = "Bearer $tokenPlain"
            Accept        = 'application/json'
        }
        ErrorAction = 'Stop'
        Verbose = $false
        Debug = $false
    } + $script:UseBasic

    if (-not ($zone = Find-IKV2Zone $RecordName $commonParams $apiRoot)) {
        throw "Unable to find matching zone for $RecordName."
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    # the API represents an apex record with a bare dot
    if ([String]::IsNullOrEmpty($recShort)) { $recShort = '.' }

    if (Find-IKV2TxtRecord $zone $recShort $RecordName $TxtValue $commonParams $apiRoot) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    try {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $queryParams = @{
            Uri = "$apiRoot/$zone/records"
            Method = 'POST'
            Body = @{
                type   = 'TXT'
                source = $recShort
                target = $TxtValue
                ttl    = 600
            } | ConvertTo-Json -Compress
            ContentType = 'application/json'
        } + $commonParams
        Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
        Invoke-RestMethod @queryParams | Out-Null
    } catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Infomaniak using their v2 API.

    .DESCRIPTION
        Add a DNS TXT record to Infomaniak using their v2 API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER InfomaniakToken
        The API token for your Infomaniak account. It must have the 'dns:read' and 'dns:write' scopes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds the specified TXT record with the specified value.
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
        [securestring]$InfomaniakToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # dns-01 values arrive bare, but dns-persist-01 values arrive already wrapped in
    # double quotes because they contain spaces. The API stores exactly one pair of
    # quotes either way, so normalize the incoming value to the quoted form and compare
    # against the stored target as-is.
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = '"{0}"' -f $TxtValue
    }

    $apiRoot = 'https://api.infomaniak.com/2/zones'

    # grab the plain text token
    $tokenPlain = [pscredential]::new('a',$InfomaniakToken).GetNetworkCredential().Password

    # build the common parameters for all API calls
    $commonParams = @{
        Headers = @{
            Authorization = "Bearer $tokenPlain"
            Accept        = 'application/json'
        }
        ErrorAction = 'Stop'
        Verbose = $false
        Debug = $false
    } + $script:UseBasic

    if (-not ($zone = Find-IKV2Zone $RecordName $commonParams $apiRoot)) {
        throw "Unable to find matching zone for $RecordName."
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    # the API represents an apex record with a bare dot
    if ([String]::IsNullOrEmpty($recShort)) { $recShort = '.' }

    $rec = Find-IKV2TxtRecord $zone $recShort $RecordName $TxtValue $commonParams $apiRoot

    if (-not $rec) {
        Write-Debug "Could not find record $RecordName to delete. Nothing to do."
        return
    }

    try {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        $queryParams = @{
            Uri = "$apiRoot/$zone/records/$($rec.id)"
            Method = 'DELETE'
        } + $commonParams
        Write-Debug "DELETE $($queryParams.Uri)"
        Invoke-RestMethod @queryParams | Out-Null
    } catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Infomaniak using their v2 API.

    .DESCRIPTION
        Remove a DNS TXT record from Infomaniak using their v2 API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER InfomaniakToken
        The API token for your Infomaniak account. It must have the 'dns:read' and 'dns:write' scopes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

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

# API Docs: https://developer.infomaniak.com/docs/api/get/2/zones/{zone}/records

function Find-IKV2Zone {
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
    if (!$script:IKV2RecordZones) { $script:IKV2RecordZones = @{} }

    # check for the record in the cache
    if ($script:IKV2RecordZones.ContainsKey($RecordName)) {
        return $script:IKV2RecordZones.$RecordName
    }

    # Unlike the v1 API, v2 addresses zones by name rather than by a numeric product ID,
    # so we can ask about a candidate zone directly instead of searching the product list.
    # We still need to find the closest/deepest sub-zone that would hold the record rather
    # than just adding it to the apex.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        try {
            $queryParams = @{
                Uri = "$ApiRoot/$zoneTest/exists"
            } + $CommonParams
            Write-Debug "GET $($queryParams.Uri)"
            $response = Invoke-RestMethod @queryParams
        } catch {
            # A zone that isn't in the account returns 404 with an 'object_not_found'
            # error body. Ignore those and re-throw anything else.
            if ($_.Exception.Response.StatusCode -ne 404) {
                throw
            }
            continue
        }

        if ($response.result -eq 'success' -and $response.data) {
            $script:IKV2RecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }

    return $null
}

function Find-IKV2TxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Zone,
        [Parameter(Mandatory, Position = 1)]
        [string]$RecShort,
        [Parameter(Mandatory, Position = 2)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 3)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 4)]
        [hashtable]$CommonParams,
        [Parameter(Mandatory, Position = 5)]
        [string]$ApiRoot
    )

    # 'with=idn' adds the source_idn field, which holds the fully qualified record name,
    # so the name comparison below can match either the relative or the fully qualified
    # form. Separately, the API always returns TXT targets wrapped in a single pair of
    # double quotes, which is why callers normalize TxtValue to the quoted form first.
    try {
        $queryParams = @{
            Uri = "$ApiRoot/$Zone/records?with=idn"
        } + $CommonParams
        Write-Debug "GET $($queryParams.Uri)"
        $recs = @(Invoke-RestMethod @queryParams | Select-Object -ExpandProperty data)
    } catch { throw }

    $recs | Where-Object {
        $_.type -eq 'TXT' -and
        ($_.source -eq $RecShort -or $_.source_idn -eq $RecordName) -and
        $_.target -eq $TxtValue
    } | Select-Object -First 1
}
