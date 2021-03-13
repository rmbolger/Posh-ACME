Function Get-CurrentPluginType { 'dns-01' }

Function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$InfomaniakToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$InfomaniakTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.infomaniak.com'

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $InfomaniakTokenInsecure = (New-Object PSCredential "user",$InfomaniakToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            Authorization = "Bearer $InfomaniakTokenInsecure"
            Accept = 'application/json'
        }
        ContentType = 'application/json'
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-InfomaniakZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $recs = Invoke-RestMethod "$apiRoot/1/domain/$($zone.id)/dns/record" `
            @restParams @Script:UseBasic -EA Stop
    } catch { throw }

    # check for a matching record
    $rec = $recs.data | Where-Object {
        $_.type -eq 'TXT' -and
        $_.source_idn -eq $RecordName -and
        $_.target_idn -eq $TxtValue
    }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # create request body schema
        $body = @{
            type = 'TXT'
            source = $recShort
            target = $TxtValue
            ttl = 600
        }
        $json = $body | ConvertTo-Json

        try {
            $response = Invoke-RestMethod "$apiRoot/1/domain/$($zone.id)/dns/record" -Method Post -Body $json `
                @restParams @Script:UseBasic -EA Stop
            if($response.result -eq 'success')
            {
                Write-Verbose "Record $RecordName added with value $TxtValue."
            }
            else
            {
                throw "Record $RecordName with value $TxtValue could not be added."
            }
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Infomaniak.
    .DESCRIPTION
        Uses the Infomaniak DNS API to add or update a DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER InfomaniakToken
        The API token for your Infomaniak account. This SecureString version can only be used on Windows or any OS running PowerShell 6.2 or later.
    .PARAMETER InfomaniakTokenInsecure
        The API token for your Infomaniak account. This standard String version may be used on any OS.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -InfomaniakTokenInsecure 'xxxxxxxx'
        Adds or updates the specified TXT record with the specified value.
    #>
}

Function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$InfomaniakToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$InfomaniakTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.infomaniak.com'

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $InfomaniakTokenInsecure = (New-Object PSCredential "user",$InfomaniakToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            Authorization = "Bearer $InfomaniakTokenInsecure"
            Accept = 'application/json'
        }
        ContentType = 'application/json'
    }

    # find matching ZoneID to check, if the records exists already
    if (-not ($zone = Find-InfomaniakZone $RecordName $restParams)) {
        throw "Unable to find matching zone for $RecordName"
    }

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $recs = Invoke-RestMethod "$apiRoot/1/domain/$($zone.id)/dns/record" `
            @restParams @Script:UseBasic -EA Stop
    } catch { throw }

    # check for a matching record
    $rec = $recs.data | Where-Object {
        $_.type -eq 'TXT' -and
        $_.source_idn -eq $RecordName -and
        $_.target_idn -eq $TxtValue
    }

    if ($rec) {
        # delete record
        try {
            $response = Invoke-RestMethod "$apiRoot/1/domain/$($zone.id)/dns/record/$($rec.id)" -Method Delete `
                @restParams @Script:UseBasic -EA Stop
            if($response.result -eq 'success')
            {
                Write-Verbose "Record $RecordName deleted."
            }
            else
            {
                throw "Record $RecordName could not be deleted."
            }
        } catch { throw }
    } else {
        Write-Debug "Could not find record $RecordName to delete. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Infomaniak.
    .DESCRIPTION
        Uses the Infomaniak DNS API to remove DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER InfomaniakToken
        The API token for your Infomaniak account. This SecureString version can only be used on Windows or any OS running PowerShell 6.2 or later.
    .PARAMETER InfomaniakTokenInsecure
        The API token for your Infomaniak account. This standard String version may be used on any OS.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -InfomaniakTokenInsecure 'xxxxxxxx'
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

# API Docs: https://api.infomaniak.com/doc

Function Find-InfomaniakZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position=1)]
        [hashtable]$RestParameters
    )

    $apiRoot = 'https://api.infomaniak.com'

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:InfomaniakRecordZones) { $script:InfomaniakRecordZones = @{} }

    # check for the record in the cache
    if ($script:InfomaniakRecordZones.ContainsKey($RecordName)) {
        Write-Debug "Result from Cache $($script:InfomaniakRecordZones.$RecordName.name) (ID $($script:InfomaniakRecordZones.$RecordName.id))"
        return $script:InfomaniakRecordZones.$RecordName
    }

    # We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com
    $zoneTest = $RecordName;
    while($zoneTest.Contains('.'))
    {
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-RestMethod -Uri "$apiRoot/1/product?service_name=domain&customer_name=$zoneTest" `
                @RestParameters @Script:UseBasic -EA Stop
            $zoneId = $response.data.id
            if($zoneId)
            {
                Write-Debug "Zone $zoneTest found. Zone ID is $zoneId"
                $script:InfomaniakRecordZones.$RecordName = @{
                    name = $zoneTest
                    id = $zoneId
                }
                return $script:InfomaniakRecordZones.$RecordName;
            }
        } catch { throw }
        # remove one sub site
        $zoneTest = $zoneTest.Split('.',2)[1]
    }

    Write-Debug "Zone for $RecordName does not exist ..."
    return $null
}
