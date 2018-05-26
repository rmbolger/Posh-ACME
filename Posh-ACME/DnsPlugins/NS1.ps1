function Add-DnsTxtNS1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$NS1Key,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # API Docs
    # https://ns1.com/api
    $apiRoot = 'https://api.nsone.net/v1'
    $restParams = @{
        Headers = @{
            Accept = 'application/json'
            'X-NSONE-Key'=((New-Object PSCredential 'user',$NS1Key).GetNetworkCredential().Password)
        }
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneName = Find-NS1Zone $RecordName $restParams
    Write-Debug "Found zone $zoneName"

    # Search for the record we care about, but ignore errors
    # because the record not existing generates an exception
    # and that's ok
    try {
        $rec = Invoke-RestMethod "$apiRoot/zones/$zoneName/$RecordName/TXT" @restParams @script:UseBasic
    } catch {}

    if (-not $rec) {
        # add new record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $bodyJson = @{zone=$zoneName;type='TXT';domain=$RecordName;ttl=10;answers=@(@{answer=@($TxtValue)})} |
            ConvertTo-Json -Compress -Depth 5
        Invoke-RestMethod "$apiRoot/zones/$zoneName/$RecordName/TXT" -Method Put -Body $bodyJson `
            @restParams @script:UseBasic | Out-Null
    } else {
        if ($TxtValue -in $rec.answers.answer) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        } else {
            # add a new answer
            $rec.answers += @{answer=@($TxtValue)}
            $bodyJson = @{answers=$rec.answers} | ConvertTo-Json -Compress -Depth 5
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            Invoke-RestMethod "$apiRoot/zones/$zoneName/$RecordName/TXT" -Method Post -Body $bodyJson `
                @restParams @script:UseBasic | Out-Null
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to NS1.

    .DESCRIPTION
        Add a DNS TXT record to NS1.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NS1Key
        A SecureString object containing the API key with DNS permissions on your NS1 account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "NS1 Key" -AsSecureString
        PS C:\>Add-DnsTxtNS1 '_acme-challenge.site1.example.com' 'asdfqwer12345678' $key

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtNS1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$NS1Key,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # API Docs
    # https://ns1.com/api
    $apiRoot = 'https://api.nsone.net/v1'
    $restParams = @{
        Headers = @{
            Accept = 'application/json'
            'X-NSONE-Key'=((New-Object PSCredential 'user',$NS1Key).GetNetworkCredential().Password)
        }
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneName = Find-NS1Zone $RecordName $restParams
    Write-Debug "Found zone $zoneName"

    # Search for the record we care about, but ignore errors
    # because the record not existing generates an exception
    # and that's ok
    try {
        $rec = Invoke-RestMethod "$apiRoot/zones/$zoneName/$RecordName/TXT" @restParams @script:UseBasic
    } catch {}

    if (-not $rec) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        if ($TxtValue -in $rec.answers.answer) {
            if ($rec.answers.Count -eq 1) {
                # last answer, so delete the record
                Write-Verbose "Deleting TXT record for $RecordName"
                Invoke-RestMethod "$apiRoot/zones/$zoneName/$RecordName/TXT" -Method Delete `
                    @restParams @script:UseBasic | Out-Null
            } else {
                # just remove the answer from the list
                $rec.answers = @($rec.answers | Where-Object { $TxtValue -notin $_.answer })
                $bodyJson = @{answers=$rec.answers} | ConvertTo-Json -Compress -Depth 5
                Write-Verbose "Removing a TXT record for $RecordName with value $TxtValue"
                Invoke-RestMethod "$apiRoot/zones/$zoneName/$RecordName/TXT" -Method Post -Body $bodyJson `
                    @restParams @script:UseBasic | Out-Null
            }
        } else {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from NS1.

    .DESCRIPTION
        Remove a DNS TXT record from NS1.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NS1Key
        A SecureString object containing the API key with DNS permissions on your NS1 account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "NS1 Key" -AsSecureString
        PS C:\>Remove-DnsTxtNS1 '_acme-challenge.site1.example.com' 'asdfqwer12345678' $key

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtNS1 {
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

function Find-NS1Zone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:NS1RecordZones) { $script:NS1RecordZones = @{} }

    # check for the record in the cache
    if ($script:NS1RecordZones.ContainsKey($RecordName)) {
        return $script:NS1RecordZones.$RecordName
    }

    $apiRoot = 'https://api.nsone.net/v1'

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    # get the list of zones
    try {
        $zones = Invoke-RestMethod "$apiRoot/zones" @RestParams @script:UseBasic
    } catch { throw }

    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"
        if ($zoneTest -in $zones.zone) {
            $zoneName = ($zones | Where-Object { $_.zone -eq $zoneTest }).zone
            $script:NS1RecordZones.$RecordName = $zoneName
            return $zoneName
        }
    }

    return $null

}
