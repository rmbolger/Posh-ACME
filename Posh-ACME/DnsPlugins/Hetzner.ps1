Function Add-DnsTxtHetzner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position = 2)]
        [string]$HetznerAPIKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot, $AuthHeaders = Get-ApiRootAndAuthHeaders $HetznerAPIKey

    # find matching ZoneID to check, if the records exists already
    if (-not ($zoneId, $zoneName = Find-HetznerZone -RecordName $RecordName -HetznerApi $apiRoot -AuthHeaders $AuthHeaders)) {
        throw "Unable zo find matching zone for $RecordName"
    }

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $recs = Invoke-RestMethod "$apiRoot/records?zone_id=$zoneId" `
            -Headers $AuthHeaders -Method Get -ContentType "application/json" @Script:UseBasic -ErrorAction Stop
    } catch { throw }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace [regex]::Escape(".$zoneName"), [string]::Empty
    $txtrec = $recs.records | Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort -and $_.value -eq $TxtValue }    

    if ($txtrec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # create request body schema
        $body = New-Object System.Object
        $body | Add-Member -type NoteProperty -name name -value $recShort
        $body | Add-Member -type NoteProperty -name ttl -value ([System.Int32] 600)
        $body | Add-Member -type NoteProperty -Name type -Value "TXT"
        $body | Add-Member -type NoteProperty -Name value -Value $TxtValue
        $body | Add-Member -type NoteProperty -Name zone_id -Value $zoneId
        $json = $body | ConvertTo-Json

        # check, if TXT-Record exists to add or update the record
        $txtrec = $recs.records | Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort }

        try {
            if ($txtrec)
            {
                Write-Verbose "Update Record $RecordName ($($txtrec.Id)) with value $TxtValue."

                $response = Invoke-RestMethod -Uri "$apiRoot/records/$($txtrec.Id)" `
                -Headers $AuthHeaders -Method Put -Body $json -ContentType "application/json" @Script:UseBasic -ErrorAction Stop
            } else {
                Write-Verbose "Add Record $RecordName with value $TxtValue."

                $response = Invoke-RestMethod -Uri "$apiRoot/records" `
                -Headers $AuthHeaders -Method Post -Body $json -ContentType "application/json" @Script:UseBasic -ErrorAction Stop
            }
        } catch { throw }
        if (-not $response.record)
        {
             throw "Hetzner API didn't add/update $RecordName"
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hetzner.
    .DESCRIPTION
        Uses the Hetzner DNS API to add or update a DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER HetznerAPIKey
        The Hetzner APIKey generated for your account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxtHetzner '_acme-challenge.example.com' 'txt-value'

        Adds or updates the specified TXT record with the specified value.
    #>    
}

Function Remove-DnsTxtHetzner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position = 2)]
        [string]$HetznerAPIKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot, $AuthHeaders = Get-ApiRootAndAuthHeaders $HetznerAPIKey

    # find matching ZoneID to check, if the records exists already
    if (-not ($zoneId, $zoneName = Find-HetznerZone -RecordName $RecordName -HetznerApi $apiRoot -AuthHeaders $AuthHeaders)) {
        throw "Unable zo find matching zone for $RecordName"
    }

    # Get a list of existing TXT records for this record name
    try {
        Write-Verbose "Searching for existing TXT record"
        $recs = Invoke-RestMethod "$apiRoot/records?zone_id=$zoneId" `
            -Headers $AuthHeaders -Method Get -ContentType "application/json" @Script:UseBasic -ErrorAction Stop
    } catch { throw }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = $RecordName -ireplace [regex]::Escape(".$zoneName"), [string]::Empty
    $txtrec = $recs.records | Where-Object { $_.type -eq 'TXT' -and $_.name -eq $recShort -and $_.value -eq $TxtValue }    

    if ($txtrec) {
        Write-Verbose "Remove Record $RecordName ($($txtrec.Id)) with value $TxtValue."

        try {
            Write-Verbose "Removing $RecordName with value $TxtValue"
            # Invoke-RestMethod -Uri "$apiRoot/records/$($txtrec.Id)" `
            #    -Headers $AuthHeaders -Method Delete @Script:UseBasic -ErrorAction Stop
        } catch { throw "Error removing Record" }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    Write-Verbose "Done!"

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hetzner.
    .DESCRIPTION
        Uses the Hetzner DNS API to add or update a DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER HetznerAPIKey
        The Hetzner APIKey generated for your account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxtHetzner '_acme-challenge.example.com' 'txt-value'

        Adds or updates the specified TXT record with the specified value.
    #>    
}

function Save-DnsTxtHetzner {
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

# API Docs: https://dns.hetzner.com/api-docs/

Function Find-HetznerZone {
    [CmdletBinding(DefaultParameterSetName='Token')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(ParameterSetName='Token',Mandatory,Position=1)]
        [Parameter(ParameterSetName='AuthHeader',Mandatory,Position=1)]
        [Alias("HetznerAuthToken")]
        [string]$HetznerApi,
        [Parameter(ParameterSetName='AuthHeader',Mandatory,Position=2)]
        [hashtable]$AuthHeaders
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:HetznerRecordZones) { $script:HetznerRecordZones = @{} }

    # check for the record in the cache
    if ($script:HetznerRecordZones.ContainsKey($RecordName)) {
        Write-Debug "Result from Cache $($script:HetznerRecordZones.$RecordName.Name)"
        return @($script:HetznerRecordZones.$RecordName.Id, $script:HetznerRecordZones.$RecordName.Name)
    }

    if (-not $AuthHeaders) {
        $apiRoot, $AuthHeaders = Get-ApiRootAndAuthHeaders $HetznerApi
    }

    # first, get all Zones, Zone to get is identified by 'ZoneID'.
    try 
    { 
        $response = Invoke-RestMethod -Uri "$apiRoot/zones"  `
            -Headers $AuthHeaders -Method Get -ContentType "application/json" @Script:UseBasic -ErrorAction Stop
    } 
    catch 
    { 
        if (-not $_.Exception.Response)
        {
            Write-Debug $_.Exception
            throw  
        } else {
            throw "Hetzner API Status Error"
            Write-Debug "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Debug "StatusDescription:" $_.Exception.Response.StatusDescription
        }
    }
     
    # We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com
    $pieces = $RecordName.Split('.')
    for ($i = 1; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        try {
            $rec = $response.zones | Where-Object {
                $_.name -eq $zoneTest
            }
        }
        catch {
            
        }

        if ($null -eq $rec) { 
            Write-Debug "Zone $zoneTest does not exist ..."
        } else {
            Write-Debug "Zone $zoneTest found."

            $zone = New-Object System.Object
            $zone | Add-Member -type NoteProperty -name Id -value $rec.id
            $zone | Add-Member -type NoteProperty -name Name -value $zoneTest

            $script:HetznerRecordZones.$RecordName = $zone

            return @($rec.id, $zoneTest)
        }
    }

    return $null

    <#      
    .SYNOPSIS
        Finds the appropriate DNS zoneID for the supplied record
    .DESCRIPTION
        Finds the appropriate DNS zoneID for the supplied record. 
    .NOTES
        If the HetznerAPI parameter is filled with the Hetzner Auth-API token, the AuthHeaders parameter must not be used. If the Hetzner API parameter is filled with the root URI of the Hetzner DNS service, the AuthHeaders parameter must be used.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER HetznerAPI - Alias HetznerAuthToken
        The Hetzner Auth-API-Token or the URI if used the AuthHeaders-Parameter.
    .PARAMETER AuthHeaders
        The Hetzner Auth-API-Header.
    .OUTPUTS
        Array of system.string, system.string. Find-HetznerZone returns an array of the ZoneID and ZoneName
    .EXAMPLE
        Find-HetznerZone -RecordName '_acme-challenge.site1.example.com' -HetznerAuthToken 'asdfqwer12345678'
        Finds the appropriate DNS zoneID for the supplied record using the Hetzner Auth-API-Token
    .EXAMPLE
        $apiRoot, $AuthHeaders = Get-ApiRootAndAuthHeaders -HetznerAuthToken 'asdfqwer12345678'   
        $zoneId, $zoneName = Find-HetznerZone -RecordName '_acme-challenge.site1.example.com' -AuthHeader $AuthHeaders -ApiRoot $apiRoot
        Finds the appropriate DNS zoneID for the supplied record using the Hetzner Auth-API-Token
    .EXAMPLE
        Find-HetznerZone -RecordName '_acme-challenge.site1.example.com' -HetznerApi 'https://dns.hetzner.com/api/v1' -AuthHeader @{'X-Consumer-Username='' 'Auth-API-Token=asdfqwer12345678' } 
        Finds the appropriate DNS zoneID for the supplied record using the Hetzner root URI and AuthHeaders.
    #>
}

Function Get-ApiRootAndAuthHeaders {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$HetznerAuthToken
    ) 

    if (-not $HetznerAuthToken) { throw "Parameter HetznerAuthTocken is missing." }

    $apiRoot = 'https://dns.hetzner.com/api/v1' 

    $AuthHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $AuthHeaders.Add("X-Consumer-Username", '')
    $AuthHeaders.Add("Auth-API-Token", $HetznerAuthToken)

    return @($apiRoot, $AuthHeaders)

    <#      
    .SYNOPSIS
        Returns the required parameters for DNS API and header parameters
    .DESCRIPTION
        Returns the required parameters for DNS API and header parameters
     .PARAMETER HetznerAuthToken
        The Hetzner Auth-API-Token.
   .EXAMPLE
        $apiRoot, $AuthHeaders = Get-ApiRootAndAuthHeaders -HetznerAuthToken 'asdfqwer12345678'

        Return the appropriate Uri amd Header Parameter
    #>
}
