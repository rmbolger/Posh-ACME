function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,

        [Parameter(Mandatory)]
        [SecureString]$PortsApiKey,

        [Parameter()]
        [ValidateSet('Production','Demo')]
        [string]$PortsEnvironment = 'Production',

        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-Ports -ApiKey $PortsApiKey -Environment $PortsEnvironment

    if (-not ($ZoneID = Find-PortsZone -RecordName $RecordName )) {
        throw "Unable to find Ports Management hosted zone for $RecordName"
    }

    # check for an existing record
    Write-Debug "Checking for existing record"
    $ExistingTXTrecords = Get-PortsDnsRecord -RecordName $RecordName -RecordType TXT

    if ($ExistingTXTrecords.Where{ $_.rdata -eq $TxtValue }) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    $DnsRecordParams = @{
        RecordName = $RecordName
        RecordType = 'TXT'
        RecordData = $TxtValue
        Comment = "Added by Posh-ACME on $(Get-Date -Format 'o')"
    }
    Add-PortsDnsRecord @DnsRecordParams | Out-Null


    <#
    .SYNOPSIS
        Add a DNS TXT record to Ports Management DNS.

    .DESCRIPTION
        Use Ports Management API to add a TXT record to a Ports Management DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PortsApiKey
        The scoped API key that has been given read/write permissions to the necessary zones.

    .PARAMETER PortsEnvironment
        The API environment to connect to. 'Production' or 'Demo' is available. Defaults to Production.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -PortsApiKey (Read-Host 'Ports API key' -AsSecureString)

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
        [SecureString]$PortsApiKey,

        [Parameter()]
        [ValidateSet('Production','Demo')]
        [string]$PortsEnvironment = 'Production',

        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-Ports -ApiKey $PortsApiKey -Environment $PortsEnvironment

    if (-not ($ZoneID = Find-PortsZone -RecordName $RecordName )) {
        throw "Unable to find Ports Management hosted zone for $RecordName"
    }

    # check for an existing record
    Write-Debug "Checking for existing record"
    $ExistingTXTrecords = Get-PortsDnsRecord -RecordName $RecordName -RecordType TXT

    if (-not $ExistingTXTrecords.Where{ $_.rdata -eq $TxtValue }) {
        Write-Debug "Record $RecordName does not contain $TxtValue. Nothing to do."
        return
    }

    Remove-PortsDnsRecord -RecordName $RecordName -RecordType 'TXT' -RecordData $TxtValue | Out-Null

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Ports Management DNS

    .DESCRIPTION
        Use Ports Management API to remove a TXT record from a Ports Management DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PortsEnvironment
        The API environment to connect to. 'Production' or 'Demo' is available. Defaults to Production.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -PortsApiKey (Read-Host 'Ports API key' -AsSecureString)

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

# Add a commented link to API docs if they exist.

# Add additional functions here if necessary.

# Try to follow verb-noun naming guidelines.
# https://msdn.microsoft.com/en-us/library/ms714428


function Get-PortsApiRootUrl {
    [CmdLetBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateSet('Production', 'Demo')]
        [string]$Environment = 'Production'
    )

    $BaseUrl = switch ($Environment) {
        'Demo' {
            'https://demo.ports.management/pmapi'
            break
        }

        'Production' {
            'https://api.ports.management'
            break
        }
    }

    return $BaseUrl

    <#
    .SYNOPSIS
        Helper function to retrieve the base API url.

    .DESCRIPTION
        Find the base API URL to make REST calls against, given API version and environment.
    
    .PARAMETER Environment
        The Ports Management has a 'Demo' endpoint of their API in addition to Production. Useful for testing.
    
    .EXAMPLE
        Get-PortsApiRootUrl

        Retrieves the default base URL, for production use
    
    .EXAMPLE
        Get-PortsApiRootUrl -Environment 'Demo'

        Retrieves the base URL for demo use    
    #>
}
function Connect-Ports {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [securestring]$ApiKey,

        [Parameter()]
        [ValidateSet('Production', 'Demo')]
        [string]$Environment = 'Production'
    )

    # Convert from user inputted SecureString API key to the API's expected plain text API key
    $ApiKeyInsecure = [PSCredential]::new('a',$ApiKey).GetNetworkCredential().Password

    # Set script-wide variables for the Ports API environment and API key
    $script:PortsApiRoot = Get-PortsApiRootUrl -Environment $Environment
    $script:PortsApiKey = $ApiKeyInsecure
    
    # setup a tracking variable for modified records
    if (-not $script:PortsModifiedRecs) { $script:PortsModifiedRecs = @{} }
}

function Invoke-PortsRestMethod {
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,

        [Parameter(Mandatory, Position=1)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method,

        [Parameter(Position=2)]
        [string]$Body
    )

    
    $Url = $script:PortsApiRoot + $Endpoint
    
    $RestSplat = @{
        Method = $Method
        Uri = $Url
        ContentType = 'application/json'
        Headers = @{
            'X-API-KEY' = $script:PortsApikey
        }
    }
    Write-Debug "$Method $Url"
    if ($PSBoundParameters.Keys -contains 'Body') { 
        $RestSplat.Body = $Body 
        Write-Debug "Body: $Body"
    }
    Invoke-RestMethod @RestSplat @script:UseBasic -ErrorAction 'Stop'

    <#
    .SYNOPSIS
        Invoke-RestMethod wrapper for Ports Management API

    .DESCRIPTION
        Used for making REST API calls against the Ports Management API
    
    .PARAMETER Endpoint
        The Ports Management API endpoint to make a request to, for example /v1/zones
    
    .EXAMPLE
        Invoke-PortsRestMethod -Endpoint '/v1/zones' -Method 'GET' -ApiKey 'p/5up3r+5ecur3=ap1_k3y-h3re'

        Retrieves all zones 
    #>
}

function Find-PortsZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:PortsRecordZones) { $script:PortsRecordZones = @{} }

    # check for the record in the cache
    if ($script:PortsRecordZones.ContainsKey($RecordName)) {
        Write-Verbose "Returning result from cache"
        return $script:PortsRecordZones.$RecordName
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $Pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {

        $ZoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        $Response = $null

        try {
            $Response = Invoke-PortsRestMethod -Endpoint "/v1/zones/$ZoneTest" -Method "Get"
        } catch {
            if (400 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Debug "Zone not found: $zoneTest"
            } else { throw }
        }

        if ($Response) {
            Write-Debug "Reponse data received for $ZoneTest"
            $ZoneID = $Response.data[0].id
            $script:PortsRecordZones.$RecordName = $ZoneID
            return $ZoneID
        }
    }

    return $null
}

function Add-PortsDnsRecord {
    #Reference: https://demo.ports.management/pmapi-doc/openapi-ui/index.html#/dns/patch_v1_zones__name_
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,

        [Parameter(Mandatory,Position=1)]
        [ValidateSet('A','AAAA','CAA','CNAME','DNAME','LOC','MX','NAPTR','NS','PTR','RP','SRV','SSHFP','TLSA','TXT')]
        [string]$RecordType,

        [Parameter(Mandatory,Position=2)]
        [string]$RecordData,

        [Parameter()]
        [int]$TTL,

        [Parameter()]
        [string]$Comment
    )

    $ZoneID = Find-PortsZone -RecordName $RecordName
    # Strip the tailing identified zone from record name
    $RecShort = ($RecordName -ireplace [regex]::Escape($ZoneId), [string]::Empty).TrimEnd('.')
    if ($RecShort -eq [string]::Empty) {
        $RecShort = '@'
    }

    # Due to the Ports Management API utilizing JSON Merge (RFC 7396) for the zone records, 
    # we cannot add or remove individual records in an array of records.
    # Therefore we need to save the existing state of the record before making changes,
    # to allow us insert our records into the existing array.

    $NewRecords = @()
    $ExistingRecords = Get-PortsDnsRecord -RecordName $RecordName -RecordType $RecordType
    if ($ExistingRecords) {$NewRecords += $ExistingRecords}
    $NewRecordData = @{rdata = $RecordData}

    if ($PSBoundParameters.Keys -contains 'TTL') {
        $NewRecordData['ttl'] = $TTL
    }

    if ($PSBoundParameters.Keys -contains 'Comment') {
        $NewRecordData['comments'] = $Comment
    }

    $NewRecords += [PSCustomObject]$NewRecordData

    $RequestData = @{
        data = @{
            type = 'zone'
            id = $ZoneID
            attributes = @{
                records = @{
                    $RecShort = @{
                        $RecordType = @(
                            $NewRecords
                        )
                    }
                }
            }
        }
    }

    $BodyJson = ConvertTo-Json -InputObject $RequestData -Depth 10 -Compress
    Invoke-PortsRestMethod -Method Patch -Endpoint "/v1/zones/$ZoneID" -Body $BodyJson
}

function Remove-PortsDnsRecord {
    #Reference: https://demo.ports.management/pmapi-doc/openapi-ui/index.html#/dns/patch_v1_zones__name_
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,

        [Parameter(Mandatory,Position=1)]
        [ValidateSet('A','AAAA','CAA','CNAME','DNAME','LOC','MX','NAPTR','NS','PTR','RP','SRV','SSHFP','TLSA','TXT')]
        [string]$RecordType,

        [Parameter(Mandatory,Position=2)]
        [string]$RecordData
    )

    $ZoneID = Find-PortsZone -RecordName $RecordName
    # Strip the tailing identified zone from record name
    $RecShort = ($RecordName -ireplace [regex]::Escape($ZoneId), [string]::Empty).TrimEnd('.')
    if ($RecShort -eq [string]::Empty) {
        $RecShort = '@'
    }

    # Due to the Ports Management API utilizing JSON Merge (RFC 7396) for the zone records, 
    # we cannot add or remove individual records in an array of records.
    # Therefore we need to save the existing state of the record before making changes,
    # to allow us remove our specific record from the existing array.

    $ExistingRecords = Get-PortsDnsRecord -RecordName $RecordName -RecordType $RecordType

    # We must only remove records with the given value, not all records of the matching record type for the same record name
    $NewRecords = $ExistingRecords.Where{$_.'rdata' -ne $RecordData}

    $RequestData = @{
        data = @{
            type = 'zone'
            id = $ZoneID
            attributes = @{
                records = @{
                    $RecShort = @{
                        $RecordType = @(
                            $NewRecords
                        )
                    }
                }
            }
        }
    }

    $BodyJson = ConvertTo-Json -InputObject $RequestData -Depth 10 -Compress
    Invoke-PortsRestMethod -Method Patch -Endpoint "/v1/zones/$ZoneID" -Body $BodyJson

}

function Get-PortsDnsRecord {
    #Reference: https://demo.ports.management/pmapi-doc/openapi-ui/index.html#/dns/get_v1_zones__name_
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,

        [Parameter(Position=1)]
        [ValidateSet('A','AAAA','CAA','CNAME','DNAME','LOC','MX','NAPTR','NS','PTR','RP','SRV','SSHFP','TLSA','TXT')]
        [string]$RecordType
    )

    $ZoneID = Find-PortsZone -RecordName $RecordName
    # Strip the tailing identified zone from record name
    $RecShort = ($RecordName -ireplace [regex]::Escape($ZoneId), [string]::Empty).TrimEnd('.')
    if ($RecShort -eq [string]::Empty) {
        $RecShort = '@'
    }

    $Response = Invoke-PortsRestMethod -Method GET -Endpoint "/v1/zones/$ZoneID"
    $Records = $Response.data.attributes.records.$RecShort
    if ($PSBoundParameters.Keys -contains 'RecordType') {
        $Records = $Records.$RecordType
    }
    return $Records
}
