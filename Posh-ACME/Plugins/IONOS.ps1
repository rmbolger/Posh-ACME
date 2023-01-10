Function Get-CurrentPluginType { 'dns-01' }

Function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position = 2)]
        [string]$IONOSPublicPrefix,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$IONOSTokenSecure,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$IONOSToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )


    $ApiRoot = "https://api.hosting.ionos.com/dns/v1/zones"
    
    # un-secure the password
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $IONOSToken = [pscredential]::new('a',$IONOSTokenSecure).GetNetworkCredential().Password
    }
    $IONOSToken = "$IONOSPublicPrefix.$IONOSToken"

    $RestParams = @{
               'Header' = @{
                            'X-API-Key' = $IONOSToken
                            'accept' = 'application/json'
                            }
               }


    # find ZoneID to check, if the records exists
    if (-not ($zone = Find-IONOSZone $RecordName $RestParams $ApiRoot)) {
						 
        throw "Unable to find matching zone for $RecordName"
    }

    # query the current text records
    try {
        Write-Verbose "Searching for existing TXT record" 
        $recs = Invoke-RestMethod "$ApiRoot/$($zone.id)" @RestParams
    } catch { throw }

    # check for a matching record
    $rec = $recs.records | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $RecordName -and
        $_.content -like "*$TxtValue*"
    }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        $RestParams.Method = 'POST'
        $RestParams.Header['Content-Type'] = 'application/json'
        # create body schema for request
        $RestParams.Body = @{
            name = $RecordName;
            type = 'TXT';
            content = $TxtValue;
            ttl  = 3600;
            disabled = 'false';
            prio = 0
        } 
        # convert to expected json format
        $RestParams.Body = ConvertTo-Json @($RestParams.Body)
        
       try {
            Write-Verbose "Add Record $RecordName with value $TxtValue." 
            Invoke-RestMethod "$ApiRoot/$($zone.id)/records" @RestParams | Out-Null
       } catch { throw }
    }
}

    <#
    .SYNOPSIS
        Add a DNS TXT record to IONOS.
    .DESCRIPTION
        Uses the IONOS DNS API to add or update a DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER IONOSToken
        The API token for your IONOS account.
    .PARAMETER IONOSTokenInsecure
        (DEPRECATED) The API token for your IONOS account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -IONOSToken $token

        Adds or updates the specified TXT record with the specified value.
    #>

Function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position = 2)]
        [string]$IONOSPublicPrefix,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$IONOSTokenSecure,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$IONOSToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $ApiRoot = "https://api.hosting.ionos.com/dns/v1/zones"

    # un-secure the password
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $IONOSToken = [pscredential]::new('a',$IONOSTokenSecure).GetNetworkCredential().Password
    }
    $IONOSToken = "$IONOSPublicPrefix.$IONOSToken"

    $RestParams = @{
               'Header' = @{
                            'X-API-Key' = $IONOSToken
                            'accept' = 'application/json'
                            }
               }

    # find ZoneID to check, if the records exists
    if (-not ($zone = Find-IONOSZone $RecordName $RestParams $ApiRoot)) {
						 
        throw "Unable to find matching zone for $RecordName"
    }
    
    # query the current text records
    try {
        Write-Verbose "Searching for existing TXT record" 
        $recs = Invoke-RestMethod "$ApiRoot/$($zone.id)" @RestParams 
    } catch { throw }

    # check for a matching record
    $rec = $recs.records | Where-Object {
        $_.type -eq 'TXT' -and
        $_.name -eq $RecordName -and
        $_.content -like "*$TxtValue*"
    }

    if ($rec) {
        try {
            $RestParams.Method = 'DELETE'
            Write-Verbose "Remove Record $RecordName ($($rec.Id)) with value $TxtValue." 
            Invoke-RestMethod "$ApiRoot/$($zone.id)/records/$($rec.Id)" @RestParams | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from IONOS.
    .DESCRIPTION
        Uses the IONOS DNS API to remove DNS TXT record.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER IONOSToken
        The API token for your IONOS account.
    .PARAMETER IONOSTokenInsecure
        (DEPRECATED) The API token for your IONOS account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -IONOSToken $token

        Removes the specified TXT record with the specified value.
    #>
}

Function Save-DnsTxt {
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
# https://developer.hosting.ionos.de/docs/dns

Function Find-IONOSZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position=1)]
        [hashtable]$restParams,
        [Parameter(Mandatory, Position=2)]
        [string]$ApiRoot
    )
	
	# setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:IONOSRecordZones) { $script:IONOSRecordZones = @{} }

    # check for the record in the cache
    if ($script:IONOSRecordZones.ContainsKey($RecordName)) {
        Write-Debug "Result from Cache $($script:IONOSRecordZones.$RecordName.Name)"
        return $script:IONOSRecordZones.$RecordName
    }
	
	# first, get all Zones, Zone to get is identified by 'ZoneID'.
    try {
		$response = Invoke-RestMethod $ApiRoot @restParams
	} catch { throw }

	# We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com
	$pieces = $RecordName.Split('.')
	    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write "Checking $zoneTest" #Write-Debug

        $zone = $response | Select-Object id,name |
            Where-Object { $_.name -eq $zoneTest }

        if ($zone) {
            Write-Debug "Zone $zoneTest found."
            $script:IONOSRecordZones.$RecordName = $zone
            return $zone
        } else {
            Write-Debug "Zone $zoneTest does not exist ..."
        }
    }

    return $null
}
