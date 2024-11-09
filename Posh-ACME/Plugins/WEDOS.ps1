function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$WedosCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zone = Find-Zone $RecordName $WedosCredential
    if (-not $zone) {
        throw "Unable to find zone for $RecordName in WEDOS"
    }
    Write-Debug "Found zone $zone"

    # setup a tracking variable for zones we need to "commit"
    if (-not $script:WedosZonesToSave) { $script:WedosZonesToSave = @() }

    if (-not (Find-TxtRec $RecordName $TxtValue $zone $WedosCredential)) {
        # empty string short names are ok for zone apex
        $recShort = ($RecordName -ireplace [regex]::Escape($zone), [string]::Empty).TrimEnd('.')
        $data = @{
            domain = $zone
            name = $recShort
            type = 'TXT'
            rdata = $TxtValue
            ttl = 300 # minimum
        }
        $null = Invoke-Wedos dns-row-add $WedosCredential -Data $data
        if ($zone -notin $script:WedosZonesToSave) {
            $script:WedosZonesToSave += $zone
        }
    }
    else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to WEDOS

    .DESCRIPTION
        Add a DNS TXT record to WEDOS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER WedosCredential
        The account username and API password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -WedosCredential (Get-Credential)

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
        [pscredential]$WedosCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zone = Find-Zone $RecordName $WedosCredential
    if (-not $zone) {
        throw "Unable to find zone for $RecordName in WEDOS"
    }
    Write-Debug "Found zone $zone"

    # setup a tracking variable for zones we need to "commit"
    if (-not $script:WedosZonesToSave) { $script:WedosZonesToSave = @() }

    if (-not ($rec = Find-TxtRec $RecordName $TxtValue $zone $WedosCredential)) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }
    else {
        $data = @{
            domain = $zone
            row_id = $rec.ID
        }
        $null = Invoke-Wedos dns-row-delete $WedosCredential -Data $data
        if ($zone -notin $script:WedosZonesToSave) {
            $script:WedosZonesToSave += $zone
        }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from WEDOS

    .DESCRIPTION
        Remove a DNS TXT record from WEDOS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER WedosCredential
        The account username and API password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -WedosCredential (Get-Credential)

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]$WedosCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    foreach ($zone in $script:WedosZonesToSave) {
        Write-Verbose "Applying changes for $zone zone"
        $data = @{
            name = $zone
        }
        $null = Invoke-Wedos dns-domain-commit $WedosCredential -Data $data
    }
    $script:WedosZonesToSave = @()

    <#
    .SYNOPSIS
        Commit changes to WEDOS zones.

    .DESCRIPTION
        Commit changes to WEDOS zones.

    .PARAMETER WedosCredential
        The account username and API password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt -WedosCredential (Get-Credential)

        Commits changes to zones modified by Add-DnsTxt and Save-DnsTxt
    #>
}

############################
# Helper Functions
############################

# https://kb.wedos.com/cs/wapi-api-rozhrani/zakladni-informace-wapi-api-rozhrani/wapi-zakladni-informace/
# https://kb.wedos.com/en/wapi-api-interface/wdns-en/wapi-wdns/

function Invoke-Wedos {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Command,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$Credential,
        [hashtable]$Data,
        [int[]]$AltGoodCodes=@()
    )

    # The auth protocol for this API is rather...unique.

    # Get a SHA1 hash of the password
    $sha1 = [Security.Cryptography.SHA1CryptoServiceProvider]::new()
    $hashBytes = $sha1.ComputeHash([Text.Encoding]::UTF8.GetBytes($Credential.GetNetworkCredential().Password))
    $pHash = [BitConverter]::ToString($hashBytes).Replace('-','').ToLower()

    # For some reason, the auth protocol requires the current 00-24 hour
    # with leading zeros specifically in the Europe/Prague time zone.
    $nowUtc = [DateTime]::UtcNow
    $hour = [TimeZoneInfo]::ConvertTimeFromUtc(
        $nowUtc,
        # Despite being "Standard" time, this will auto-convert
        # to "Summer" time when appropriate.
        [TimeZoneInfo]::FindSystemTimeZoneById('Central Europe Standard Time')
    ).ToString('HH')

    # Concatenate the username, hashed password, and hour
    # and then SHA1 hash the whole thing
    $authRaw = '{0}{1}{2}' -f $Credential.Username,$pHash,$hour
    Write-Debug "authRaw = $authRaw"
    $hashBytes = $sha1.ComputeHash([Text.Encoding]::UTF8.GetBytes($authRaw))
    $auth = [BitConverter]::ToString($hashBytes).Replace('-','').ToLower()

    # Build the request object
    $req = @{
        request = @{
            user = $Credential.UserName
            auth = $auth
            clTRID = "Posh-ACME $(New-Guid)" # client request ID
            command = $Command
        }
    }
    if ($Data) {
        $req.request.data = $Data
    }

    $queryParams = @{
        Uri = 'https://api.wedos.com/wapi/json'
        Method = 'POST'
        # Send the JSON request as a value of "request" that is
        # application/x-www-form-urlencoded instead of just raw JSON
        Body = @{request=($req | ConvertTo-Json -Compress -Depth 10)}
        Verbose = $false
        ErrorAction = 'Stop'
    }
    Write-Debug "POST $($queryParams.Uri)`n$($req|ConvertTo-Json -Depth 10)"
    $resp = Invoke-RestMethod @queryParams @script:UseBasic
    Write-Debug "Response:`n$($resp|ConvertTo-Json -Depth 10)"

    if ($resp.response.code -ne 1000 -and $resp.response.code -notin $AltGoodCodes) {
        "WEDOS API Error $($resp.response.code): $($resp.response.result)"
    }
    return $resp.response.data
}

function Find-Zone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$Credential
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later and uses fewer API calls
    if (!$script:WedosRecordZones) { $script:WedosRecordZones = @{} }

    # check for the record in the cache
    if ($script:WedosRecordZones.ContainsKey($RecordName)) {
        return $script:WedosRecordZones.$RecordName
    }

    # Get all of the domains on the account
    $resp = Invoke-Wedos dns-domains-list $Credential

    # For some unknown reason, the dns-domains-list command can returns the domain data
    # in two different ways. It seems to be account specific, but we don't have enough
    # sample data to know why a given account uses one format or another. Maybe region
    # specific? Maybe age of the account?
    # Regardless, we need to account for both potential responses to get the zone data.
    # Example 1: An array of zone objects
    # {
    #   "domain": [
    #     {"name": "example.com", "type": "primary", "status": "active"},
    #     {"name": "example.net", "type": "primary", "status": "active"}
    #   ]
    # }
    # Example 2: And object with numeric keys and zone object values
    # {
    #   "domain": {
    #     "24": {"name": "example.com", "type": "primary", "status": "active"},
    #     "11": {"name": "example.net", "type": "primary", "status": "active"}
    #   }
    # }
    if ($resp.domain -is [array]) {
        # We can use the array as-is
        $zones = $resp.domain
    } else {
        # The only properties should be zone objects, so just get them all
        $zones = $resp.domain.PSObject.Properties.Value
    }

    if (-not $zones) {
        Write-Warning "No WEDOS hosted domains found."
        return
    }

    # find the zone for the closest/deepest sub-zone that would contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        $match = $zones | Where-Object { $zoneTest -eq $_.name } | Select-Object -First 1
        if ($match) {
            $script:WedosRecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }
}

function Find-TxtRec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$Zone,
        [Parameter(Mandatory,Position=3)]
        [pscredential]$Credential
    )

    # Get all of the records in the zone
    $recs = Invoke-Wedos dns-rows-list $Credential -Data @{domain=$Zone} | Select-Object -Expand row
    if (-not $recs) {
        Write-Warning "No WEDOS records found."
        return
    }

    return $recs | Where-Object {
        $RecordName -eq "$($_.name).$Zone".Trim('.') -and
        $_.rdtype -eq 'TXT' -and
        $_.rdata -eq $TxtValue
    }
}
