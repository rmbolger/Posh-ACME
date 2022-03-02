function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [securestring]$LSWApiKey,
        [string]$LSWApiBase = 'https://api.leaseweb.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add the API key to an auth header
    $apikey = [pscredential]::new('a',$LSWApiKey).GetNetworkCredential().Password
    $authHeader = @{ 'x-lsw-auth' = $apikey }

    # Find the domain for the record
    if (-not ($zone = Find-LSWZone $RecordName $LSWApiBase $authHeader)) {
        throw "Domain match not found for $RecordName."
    }
    Write-Verbose "Found domain $zone"

    # check for existing record
    $rec = Get-LSWTxtRecord $RecordName $zone $LSWApiBase $authHeader

    if ($rec) {
        if ($TxtValue -in $rec.content) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        } else {
            # update the existing record
            $queryParams = @{
                Uri = "$LSWApiBase/hosting/v2/domains/$zone/resourceRecordSets/$RecordName/TXT"
                Method = 'PUT'
                Body = [ordered]@{
                    content = $rec.content + @( $TxtValue )
                    ttl = 60
                } | ConvertTo-Json
                Headers = $authHeader
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "PUT $($queryParams.Uri)`n$($queryParams.Body)"
            Write-Verbose "Adding TXT record value $TxtValue to $RecordName"
            try {
                Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
            } catch { throw }
        }
    } else {
        # create a new record from scratch
        $queryParams = @{
            Uri = "$LSWApiBase/hosting/v2/domains/$zone/resourceRecordSets"
            Method = 'POST'
            Body = [ordered]@{
                name = $RecordName
                type = 'TXT'
                content = @( $TxtValue )
                ttl = 60
            } | ConvertTo-Json
            Headers = $authHeader
            ContentType = 'application/json'
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
        Write-Verbose "Adding new TXT record for $RecordName"
        try {
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        } catch { throw }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to LeaseWeb

    .DESCRIPTION
        Add a DNS TXT record to LeaseWeb

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LSWApiKey
        The API key for your LeaseWeb account.

    .PARAMETER LSWApiBase
        The root url for the LeaseWeb API. Defaults to 'https://api.leaseweb.com'

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $apikey = Read-Host "API Key" -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -LSWApiKey $apikey

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
        [securestring]$LSWApiKey,
        [string]$LSWApiBase = 'https://api.leaseweb.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add the API key to an auth header
    $apikey = [pscredential]::new('a',$LSWApiKey).GetNetworkCredential().Password
    $authHeader = @{ 'x-lsw-auth' = $apikey }

    # Find the domain for the record
    if (-not ($zone = Find-LSWZone $RecordName $LSWApiBase $authHeader)) {
        throw "Domain match not found for $RecordName."
    }
    Write-Verbose "Found domain $zone"

    # check for existing record
    $rec = Get-LSWTxtRecord $RecordName $zone $LSWApiBase $authHeader

    if ($rec -and $TxtValue -in $rec.content) {
        if ($rec.content.Count -eq 1) {
            # delete the record entirely
            $queryParams = @{
                Uri = "$LSWApiBase/hosting/v2/domains/$zone/resourceRecordSets/$RecordName/TXT"
                Method = 'DELETE'
                Headers = $authHeader
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "DELETE $($queryParams.Uri)"
            Write-Verbose "Removing TXT record for $RecordName"
            try {
                Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
            } catch { throw }
        } else {
            # update the record to remove this value
            $queryParams = @{
                Uri = "$LSWApiBase/hosting/v2/domains/$zone/resourceRecordSets/$RecordName/TXT"
                Method = 'PUT'
                Body = [ordered]@{
                    content = $rec.content | Where-Object { $_ -ne $TxtValue }
                    ttl = 60
                } | ConvertTo-Json
                Headers = $authHeader
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "PUT $($queryParams.Uri)`n$($queryParams.Body)"
            Write-Verbose "Removing TXT record value $TxtValue from $RecordName"
            try {
                Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
            } catch { throw }
        }
    } else {
        Write-Debug "Could not find record $RecordName with $TxtValue to delete. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from LeaseWeb

    .DESCRIPTION
        Remove a DNS TXT record from LeaseWeb

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LSWApiKey
        The API key for your LeaseWeb account.

    .PARAMETER LSWApiBase
        The root url for the LeaseWeb API. Defaults to 'https://api.leaseweb.com'

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $apikey = Read-Host "API Key" -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -LSWApiKey $apikey

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

# https://developer.leaseweb.com/

function Find-LSWZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ApiBase,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$AuthHeader
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:LSWRecordZones) { $script:LSWRecordZones = @{} }

    # check for the record in the cache
    if ($script:LSWRecordZones.ContainsKey($RecordName)) {
        return $script:LSWRecordZones.$RecordName
    }

    # We can't make any assumptions about the portions of the FQDN that make
    # up the root domain. So ask the API for about each possibility, longest to
    # shortest until we find a match.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $queryParams = @{
                Uri = "$ApiBase/hosting/v2/domains/$zoneTest"
                Headers = $AuthHeader
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "GET $($queryParams.Uri)"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch {
            # 400/404 responses mean the zone wasn't found, so skip to the next check
            if ($_.Exception.Response.StatusCode -in 400,404) {
                continue
            }
            # re-throw anything else
            throw
        }

        if ($response) {
            $script:LSWRecordZones.$RecordName = $response.domainName
            return $response.domainName
        }
    }

    return $null

}

function Get-LSWTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ZoneName,
        [Parameter(Mandatory,Position=2)]
        [string]$ApiBase,
        [Parameter(Mandatory,Position=3)]
        [hashtable]$AuthHeader
    )

    try {
        $queryParams = @{
            Uri = "$ApiBase/hosting/v2/domains/$ZoneName/resourceRecordSets/$RecordName/TXT"
            Headers = $AuthHeader
            ContentType = 'application/json'
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "GET $($queryParams.Uri)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch {
        # 404 responses mean the record wasn't found, so just return
        if (404 -eq $_.Exception.Response.StatusCode) {
            return
        }
        # re-throw anything else
        throw
    }

    return $response
}
