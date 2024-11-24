function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$BunnyAccessKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $AccessKeyInsecure = [pscredential]::new('a', $BunnyAccessKey).GetNetworkCredential().Password

    $apiRoot = 'https://api.bunny.net/dnszone'

    $restParams = @{
        Headers     = @{AccessKey = "$AccessKeyInsecure" }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }

    # get the zone id for our record
    $zoneResult = Find-BunnyZone $RecordName $restParams

    if ($null -eq $zoneResult) {
        throw "Unable to find zone for $RecordName in account $acctID"
    }

    Write-Debug "Found zone $($zoneResult.Id) $($zoneResult.ZoneName)"

    # check if TXT record with this value already exists
    try {
        $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneResult.ZoneName.TrimEnd('.')))$",''
        $resultSet = (Invoke-RestMethod "$apiRoot/$($zoneResult.Id)" @restParams -Method Get)
        $existingRecs = $resultSet.Records | ? { $_.Name -eq $recShort -and $_.Type -eq 3 -and $_.Value -eq $TxtValue }
    }
    catch { throw }

    if ($existingRecs.Count -eq 0) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $bodyJson = @{Name = $recShort; Value = $TxtValue; ttl = 15; Type = 3 } | ConvertTo-Json -Compress
            Invoke-RestMethod "$apiRoot/$($zoneResult.Id)/records" -Method Put -Body $bodyJson @restParams | Out-Null
        }
        catch { throw }
    }
    else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Bunny.net DNS.

    .DESCRIPTION
        Add a DNS TXT record to Bunny.net

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AccessKey
        The API AccessKey

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $accessKey = Read-Host "Bunny.net Access Key" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $accessKey

        Adds a TXT record for the specified site with the specified value on Windows.
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
        [securestring]$BunnyAccessKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $AccessKeyInsecure = [pscredential]::new('a', $BunnyAccessKey).GetNetworkCredential().Password

    $apiRoot = 'https://api.bunny.net/dnszone'
    $restParams = @{
        Headers     = @{AccessKey = "$AccessKeyInsecure" }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }

    # get the zone id for our record
    $zoneResult = Find-BunnyZone $RecordName $restParams
    if ($null -eq $zoneResult) {
        throw "Unable to find zone for $RecordName in account $acctID"
    }

    Write-Debug "Found zone $($zoneResult.Id) $($zoneResult.ZoneName)"

    # get all the instances of the record
    try {
        $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneResult.ZoneName.TrimEnd('.')))$",''
        $resultSet = (Invoke-RestMethod "$apiRoot/$($zoneResult.Id)" @restParams -Method Get)
        $existingRecs = $resultSet.Records | ? { $_.Name -eq $recShort -and $_.Type -eq 3 -and $_.Value -eq $TxtValue }
    }
    catch { throw }

    if ($existingRecs.Count -eq 0) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }
    else {

        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            Invoke-RestMethod "$apiRoot/$($zoneResult.Id)/records/$($existingRecs[0].Id)" -Method Delete  @restParams | Out-Null
        }
        catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Bunny.net.

    .DESCRIPTION
        Remove a DNS TXT record from Bunny.net.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AccessKey
        The API AccessKey.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $accessKey = Read-Host "Bunny.net Access Key" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $accessKey

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
# https://docs.bunny.net/reference/dnszonepublic_index

function Find-BunnyZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:BunnyRecordZones) { $script:BunnyRecordZones = @{} }

    # check for the record in the cache
    if ($script:BunnyRecordZones.ContainsKey($RecordName)) {
        return $script:BunnyRecordZones.$RecordName
    }

    $apiUrl = 'https://api.bunny.net/dnszone'
    $zoneResult = $null

    try {

        [Object[]]$Zones = Invoke-RestMethod $apiUrl @RestParams -Method Get

        Write-Debug "Search for the zone from longest to shortest set of FQDN pieces"
        $pieces = $RecordName.Split('.')
        for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
            $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
            Write-Debug "Checking $zoneTest"
            try {
                Write-Debug "Check for results"
                [Object[]]$result = @($Zones.Items | Where-Object { $_.Domain -eq $zoneTest })
                if ($result.Count -gt 0) {

                    $zoneResult = @{
                        Id       = $result.Id
                        ZoneName = $result.Domain
                    }
                }
            }
            catch {
                Write-Debug "Caught an error, $($_.Exception.Message)"
                throw
            }
        }

    }
    catch { Write-Debug "Caught an error, $($_.Exception.Message)"; throw }

    return $zoneResult
}
