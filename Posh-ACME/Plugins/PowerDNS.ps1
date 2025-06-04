function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$PowerDNSApiHost,
        [Parameter(Mandatory)]
        [securestring]$PowerDNSApiKey,
        [string]$PowerDNSServerName='localhost',
        [int]$PowerDNSPort=8081,
        [switch]$PowerDNSUseTLS,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the api key
    $ApiKey = [pscredential]::new('a',$PowerDNSApiKey).GetNetworkCredential().Password

    # build the API root url
    $proto = if ($PowerDNSUseTLS) {'https'} else {'http'}
    $port = if ($PowerDNSUseTLS -and $PowerDNSPort -eq 443) {''} else {":$PowerDNSPort"}
    $ApiBase = "{0}://{1}{2}/api/v1/servers/{3}" -f $proto,$PowerDNSApiHost,$port,$PowerDNSServerName

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneName = Find-Zone $RecordName $ApiBase $ApiKey
    if (-not $zoneName) {
        throw "Unable to find PowerDNS zone for $RecordName"
    }
    $zoneBase = '{0}/zones/{1}' -f $ApiBase,$zoneName

    # check if the record already exists
    $queryParams = @{
        Uri = '{0}?rrsets=true&rrset_name={1}.&rrset_type=TXT' -f $zoneBase,$RecordName
        Headers = @{'X-API-Key' = $ApiKey}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
    }
    Write-Debug "GET $($queryParams.Uri)"
    $rrset = Invoke-RestMethod @queryParams @script:UseBasic | Select-Object -Expand rrsets

    if (-not $rrset) {
        # no matching record at all yet
        # so build a new one
        $rrsets = @{
            rrsets = @(
                @{
                    name       = "$RecordName."
                    type       = 'TXT'
                    ttl        = 60
                    changetype = 'REPLACE'
                    records    = @(
                        @{ content = "`"$TxtValue`"" }
                    )
                }
            )
        }
    }
    elseif ("`"$TxtValue`"" -notin $rrset.records.content) {
        # no matching value in the existing record
        # so add it to the existing rrset
        $rrset.records += [pscustomobject]@{content = "`"$TxtValue`""}
        $rrset | Add-Member 'changetype' 'REPLACE'
        $rrsets = @{
            rrsets = @($rrset)
        }
    }
    else {
        Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
        return
    }

    # write the updated rrset
    $queryParams = @{
        Uri = $zoneBase
        Method = 'PATCH'
        Body = ($rrsets | ConvertTo-Json -Dep 10)
        Headers = @{'X-API-Key' = $ApiKey}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
    }
    Write-Verbose "Adding $RecordName with value $TxtValue"
    Write-Debug "PATCH $($queryParams.Uri)`n$($queryParams.Body)"
    Invoke-RestMethod @queryParams @script:UseBasic

    <#
    .SYNOPSIS
        Add a DNS TXT record to PowerDNS.

    .DESCRIPTION
        Add a DNS TXT record to PowerDNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PowerDNSApiHost
        The hostname or IP address of the Power DNS API

    .PARAMETER PowerDNSApiKey
        The Power DNS API Key

    .PARAMETER PowerDNSServerName
        The internal name of the server. Defaults to "localhost"

    .PARAMETER PowerDNSPort
        The TCP port number the API is listening on. Defaults to 8081

    .PARAMETER PowerDNSUseTLS
        When specified, try to use HTTPS to connect to the API. Otherwise, HTTP.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        $pluginArgs = @{PowerDNSApiHost='pdns.example.com'; PowerDNSApiKey=$key}
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' @pluginArgs

        Adds a TXT record for the specified site/value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$PowerDNSApiHost,
        [Parameter(Mandatory)]
        [securestring]$PowerDNSApiKey,
        [string]$PowerDNSServerName='localhost',
        [int]$PowerDNSPort=8081,
        [switch]$PowerDNSUseTLS,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the api key
    $ApiKey = [pscredential]::new('a',$PowerDNSApiKey).GetNetworkCredential().Password

    # build the API root url
    $proto = if ($PowerDNSUseTLS) {'https'} else {'http'}
    $port = if ($PowerDNSUseTLS -and $PowerDNSPort -eq 443) {''} else {":$PowerDNSPort"}
    $ApiBase = "{0}://{1}{2}/api/v1/servers/{3}" -f $proto,$PowerDNSApiHost,$port,$PowerDNSServerName

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneName = Find-Zone $RecordName $ApiBase $ApiKey
    if (-not $zoneName) {
        throw "Unable to find PowerDNS zone for $RecordName"
    }
    $zoneBase = '{0}/zones/{1}' -f $ApiBase,$zoneName

    # check if the record already exists
    $queryParams = @{
        Uri = '{0}?rrsets=true&rrset_name={1}.&rrset_type=TXT' -f $zoneBase,$RecordName
        Headers = @{'X-API-Key' = $ApiKey}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
    }
    Write-Debug "GET $($queryParams.Uri)"
    $rrset = Invoke-RestMethod @queryParams @script:UseBasic | Select-Object -Expand rrsets

    if (-not $rrset -or "`"$TxtValue`"" -notin $rrset.records.content) {
        Write-Debug "Record $RecordName with value $TxtValue does not exist. Nothing to do."
        return
    }
    elseif ($rrset.records.Count -gt 1) {
        Write-Debug "records count = $($rrset.records.Count)"
        # more than one value exists with ours
        # so remove it from the existing rrset
        $rrset.records = @($rrset.records | Where-Object { $_.content -ne "`"$TxtValue`"" })
        $rrset | Add-Member 'changetype' 'REPLACE'
        $rrsets = @{
            rrsets = @($rrset)
        }
    }
    else {
        # our value is the only one left, so delete the whole record
        $rrset | Add-Member 'changetype' 'DELETE'
        $rrsets = @{
            rrsets = @($rrset)
        }
    }

    # write the updated rrset
    $queryParams = @{
        Uri = $zoneBase
        Method = 'PATCH'
        Body = ($rrsets | ConvertTo-Json -Dep 10)
        Headers = @{'X-API-Key' = $ApiKey}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
    }
    Write-Verbose "Removing $RecordName with value $TxtValue"
    Write-Debug "PATCH $($queryParams.Uri)`n$($queryParams.Body)"
    Invoke-RestMethod @queryParams @script:UseBasic

    <#
    .SYNOPSIS
        Remove a DNS TXT record from PowerDNS.

    .DESCRIPTION
        Remove a DNS TXT record from PowerDNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PowerDNSApiHost
        The hostname or IP address of the Power DNS API

    .PARAMETER PowerDNSApiKey
        The Power DNS API Key

    .PARAMETER PowerDNSServerName
        The internal name of the server. Defaults to "localhost"

    .PARAMETER PowerDNSPort
        The TCP port number the API is listening on. Defaults to 8081

    .PARAMETER PowerDNSUseTLS
        When specified, try to use HTTPS to connect to the API. Otherwise, HTTP.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        $pluginArgs = @{PowerDNSApiHost='pdns.example.com'; PowerDNSApiKey=$key}
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' @pluginArgs

        Removes a TXT record for the specified site/value.
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

# https://doc.powerdns.com/authoritative/http-api/index.html#working-with-the-api

function Find-Zone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ApiBase,
        [Parameter(Mandatory,Position=2)]
        [string]$ApiKey
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:PowerDNSRecordZones) { $script:PowerDNSRecordZones = @{} }

    # check for the record in the cache
    if ($script:PowerDNSRecordZones.ContainsKey($RecordName)) {
        return $script:PowerDNSRecordZones.$RecordName
    }

    # Find the closest/deepest sub-zone that would hold the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        try {
            $queryParams = @{
                Uri = "$ApiBase/zones/$zoneTest."   # PowerDNS very strict about trailing "."
                Headers = @{'X-API-Key' = $ApiKey}
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "GET $($queryParams.Uri)"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch {
            # 404 responses mean the zone wasn't found
            # 403 means the API key doesn't have access to query this particular zone
            # In both cases, we'll ignore and keep checking
            if (404,403 -contains $_.Exception.Response.StatusCode) {
                continue
            }
            # re-throw anything else
            throw
        }

        if ($response) {
            $script:PowerDNSRecordZones.$RecordName = $response.name
            return $response.name
        }
    }

    return $null
}
