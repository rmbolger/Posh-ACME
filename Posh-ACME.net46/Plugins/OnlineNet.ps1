function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$ONToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $ONTokenInsecure = [pscredential]::new('a',$ONToken).GetNetworkCredential().Password
    $authHeader = @{Authorization="Bearer $ONTokenInsecure"}

    # get the zone name for our record
    $zoneName = Find-Zone $RecordName $authHeader
    if ([String]::IsNullOrWhiteSpace($zoneName)) {
        throw "Unable to find zone for $RecordName"
    }
    Write-Debug "Found zone $zoneName"

    # grab the relative portion of the fqdn
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    if ($recShort -eq [string]::Empty) { $recShort = '@' }

    $rec = Find-TxtRec $recShort $zoneName $TxtValue $authHeader

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        # build the change object
        $newRec = @(
            @{
                changeType = 'ADD'
                name = $recShort
                type = 'TXT'
                records = @(
                    @{
                        name = $recShort
                        type = 'TXT'
                        ttl  = 300
                        data = "`"$TxtValue`""
                    }
                )
            }
        )

        # build the request
        $queryParams = @{
            Uri = 'https://api.online.net/api/v1/domain/{0}/version/active' -f $zoneName
            Method = 'PATCH'
            Body = ConvertTo-Json $newRec -Compress -Depth 5
            Headers = $authHeader
            ContentType = 'application/json'
            Verbose = $false
            ErrorAction = 'Stop'
        }

        # send the request
        try {
            Write-Debug "$($queryParams.Method) $($queryParams.Uri)`n$($queryParams.Body)"
            Invoke-RestMethod @queryParams @script:UseBasic
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to online.net.

    .DESCRIPTION
        Add a DNS TXT record to online.net

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ONToken
        The access API token for online.net

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "online.net Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds a TXT record for the specified site with the specified value on Windows.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$ONToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $ONTokenInsecure = [pscredential]::new('a',$ONToken).GetNetworkCredential().Password
    $authHeader = @{Authorization="Bearer $ONTokenInsecure"}

    # get the zone name for our record
    $zoneName = Find-Zone $RecordName $authHeader
    if ([String]::IsNullOrWhiteSpace($zoneName)) {
        throw "Unable to find zone for $RecordName"
    }
    Write-Debug "Found zone $zoneName"

    # grab the relative portion of the fqdn
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    if ($recShort -eq [string]::Empty) { $recShort = '@' }

    $rec = Find-TxtRec $recShort $zoneName $TxtValue $authHeader

    if ($rec) {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"

        # build the change object
        $newRec = @(
            @{
                changeType = 'DELETE'
                name = $recShort
                type = 'TXT'
                data = "`"$TxtValue`""
                # records = @(
                #     @{
                #         name = $recShort
                #         type = 'TXT'
                #         ttl  = 300
                #         data = "`"$TxtValue`""
                #     }
                # )
            }
        )

        # build the request
        $queryParams = @{
            Uri = 'https://api.online.net/api/v1/domain/{0}/version/active' -f $zoneName
            Method = 'PATCH'
            Body = ConvertTo-Json $newRec -Compress -Depth 5
            Headers = $authHeader
            ContentType = 'application/json'
            Verbose = $false
            ErrorAction = 'Stop'
        }

        # send the request
        try {
            Write-Debug "$($queryParams.Method) $($queryParams.Uri)`n$($queryParams.Body)"
            Invoke-RestMethod @queryParams @script:UseBasic
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from online.net.

    .DESCRIPTION
        Remove a DNS TXT record from online.net.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ONToken
        The access API token for online.net.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "online.net Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes a TXT record for the specified site with the specified value on Windows.
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
# https://console.online.net/en/api/

function Find-Zone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$AuthHeader
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:ONRecordZones) { $script:ONRecordZones = @{} }

    # check for the record in the cache
    if ($script:ONRecordZones.ContainsKey($RecordName)) {
        return $script:ONRecordZones.$RecordName
    }

    # find the portion of the record that matches the zone name
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $queryParams = @{
                Uri = 'https://api.online.net/api/v1/domain/{0}' -f $zoneTest
                Method = 'GET'
                Headers = $AuthHeader
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "$($queryParams.Method) $($queryParams.Uri)"
            # if the call succeeds, the zone exists, so we don't care about the actual response
            $resp = Invoke-RestMethod @queryParams @script:UseBasic
            Write-Debug "Response`n$($resp | ConvertTo-Json -Dep 10)"
            $script:ONRecordZones.$RecordName = $zoneTest
            return $zoneTest
        } catch {
            if (404 -ne $_.Exception.Response.StatusCode) { throw }
            Write-Debug ($_.ToString())
        }
    }

    return $null
}

function Find-TxtRec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecShort,
        [Parameter(Mandatory,Position=1)]
        [string]$ZoneName,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=3)]
        [hashtable]$AuthHeader
    )

    # query the record data and return a matching TXT record if it exists
    Write-Debug "Querying $ZoneName records"
    $queryParams = @{
        Uri = 'https://api.online.net/api/v1/domain/{0}/zone' -f $ZoneName
        Method = 'GET'
        Headers = $AuthHeader
        Verbose = $false
        ErrorAction = 'Stop'
    }
    try {
        Write-Debug "GET $($queryParams.Uri)"
        $recs = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug "$($recs.Count) records returned"
    } catch { throw }

    $rec = $recs | Where-Object {
        $_.name -eq $RecShort -and
        $_.data -eq "`"$TxtValue`""
    }

    return $rec
}
