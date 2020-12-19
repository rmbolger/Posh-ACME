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

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneName = Find-DOZone $RecordName "Bearer $DOToken"
    if (-not $zoneName) {
        throw "Unable to find Digital Ocean hosted zone for $RecordName"
    }

    $recRoot = "https://api.digitalocean.com/v2/domains/$zoneName/records"

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    if ($recShort -eq [string]::Empty) {
        $recShort = '@'
    }

    # query the current text record
    try {
        $queryParams = @{
            Uri = $recRoot
            Headers = @{
                Authorization = "Bearer $DOToken"
            }
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($queryParams.Uri)"
        $rec = (Invoke-RestMethod @queryParams @script:UseBasic).domain_records |
                Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort -and $_.data -eq $TxtValue }
    } catch { throw }

    if (-not $rec) {

        # modify the query params to create a new record
        $queryParams.Method = 'Post'
        $queryParams.Body = @{
            type = 'TXT';
            name = $recShort;
            data = $TxtValue;
            ttl  = 30;
        } | ConvertTo-Json

        Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Invoke-RestMethod @queryParams @script:UseBasic | Out-Null

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

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneName = Find-DOZone $RecordName "Bearer $DOToken"
    if (-not $zoneName) {
        throw "Unable to find Digital Ocean hosted zone for $RecordName"
    }

    $recRoot = "https://api.digitalocean.com/v2/domains/$zoneName/records"

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    if ($recShort -eq [string]::Empty) {
        $recShort = '@'
    }

    # query the current text record
    try {
        $queryParams = @{
            Uri = $recRoot
            Headers = @{
                Authorization = "Bearer $DOToken"
            }
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($queryParams.Uri)"
        $rec = (Invoke-RestMethod @queryParams @script:UseBasic).domain_records |
                Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort -and $_.data -eq $TxtValue }
    } catch { throw }

    if ($rec) {
        # modify the query params to delete the record
        $queryParams.Method = 'DELETE'
        $queryParams.Uri = "{0}/{1}" -f $queryParams.Uri,$rec.id

        Write-Debug "DELETE $($queryParams.Uri)"
        Write-Verbose "Deleting $RecordName with value $TxtValue"
        Invoke-RestMethod @queryParams @script:UseBasic | Out-Null

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
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$BearerHeader,
        [string]$ApiRoot = 'https://api.digitalocean.com/v2/domains'
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DORecordZones) { $script:DORecordZones = @{} }

    # check for the record in the cache
    if ($script:DORecordZones.ContainsKey($RecordName)) {
        return $script:DORecordZones.$RecordName
    }

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        try {
            $queryParams = @{
                Uri = "$ApiRoot/$zoneTest"
                Headers = @{
                    Authorization = $BearerHeader
                }
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "GET $($queryParams.Uri)"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch {
            # ignore 404 errors, throw anything else
            if ([Net.HttpStatusCode]::NotFound -eq $_.Exception.Response.StatusCode) {
                continue
            } else {
                throw
            }
        }

        if ($response.domain.name) {
            $script:DORecordZones.$RecordName = $response.domain.name
            return $response.domain.name
        } else {
            throw "DigitalOcean zone query succeeded, but didn't return expected results.`n$($response | ConvertTo-Json)"
        }
    }

    return $null
}
