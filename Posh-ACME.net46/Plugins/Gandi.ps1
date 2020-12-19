function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='PAT')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='PAT')]
        [securestring]$GandiPAT,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$GandiToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$GandiTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Build the appropriate auth header depending on what type of token was used.
    $RestHeaders = @{Accept = 'application/json'}
    if ('PAT' -eq $PSCmdlet.ParameterSetName) {
        $pat = [pscredential]::new('a',$GandiPAT).GetNetworkCredential().Password
        $RestHeaders.Authorization = "Bearer $pat"
    }
    else {
        if ('Secure' -eq $PSCmdlet.ParameterSetName) {
            $GandiTokenInsecure = [pscredential]::new('a',$GandiToken).GetNetworkCredential().Password
        }
        $RestHeaders.'X-Api-Key' = $GandiTokenInsecure
    }

    # get the zone name for our record
    $zoneName = Find-GandiZone $RecordName $RestHeaders
    Write-Debug "Found zone $zoneName"

    # find the matching TXT record if it exists
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if (-not $recShort) { $recShort = '@' }
    $recUrl = "https://dns.api.gandi.net/api/v5/domains/$zoneName/records/$recShort/TXT"
    try {
        $queryParams = @{
            Uri = $recUrl
            Headers = $RestHeaders
            ContentType = 'application/json'
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($queryParams.Uri)"
        $rec = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug "Response:`n$($rec | ConvertTo-Json)"
    } catch {}

    if ($rec -and "`"$TxtValue`"" -in $rec.rrset_values) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        if (-not $rec) {
            # add new record
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $queryParams = @{
                Method = 'POST'
                Body = (@{rrset_values=@("`"$TxtValue`"")} | ConvertTo-Json -Compress)
            }
        } else {
            # update the existing record
            Write-Verbose "Updating a TXT record for $RecordName with value $TxtValue"
            $queryParams = @{
                Method = 'PUT'
                Body = (@{rrset_values=(@($rec.rrset_values) + @("`"$TxtValue`""))} | ConvertTo-Json -Compress)
            }
        }

        $queryParams.Uri = $recUrl
        $queryParams.Headers = $RestHeaders
        $queryParams.ContentType = 'application/json'
        $queryParams.Verbose = $false
        $queryParams.ErrorAction = 'Stop'
        try {
            Write-Debug "$($queryParams.Method) $($queryParams.Uri)`n$($queryParams.Body)"
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Gandi.

    .DESCRIPTION
        Add a DNS TXT record to Gandi.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GandiToken
        The API token for your Gandi account.

    .PARAMETER GandiTokenInsecure
        (DEPRECATED) The API token for your Gandi account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Gandi Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds a TXT record using a securestring object for GandiToken. (Only works on Windows)
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='PAT')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='PAT')]
        [securestring]$GandiPAT,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$GandiToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$GandiTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Build the appropriate auth header depending on what type of token was used.
    $RestHeaders = @{Accept = 'application/json'}
    if ('PAT' -eq $PSCmdlet.ParameterSetName) {
        $pat = [pscredential]::new('a',$GandiPAT).GetNetworkCredential().Password
        $RestHeaders.Authorization = "Bearer $pat"
    }
    else {
        if ('Secure' -eq $PSCmdlet.ParameterSetName) {
            $GandiTokenInsecure = [pscredential]::new('a',$GandiToken).GetNetworkCredential().Password
        }
        $RestHeaders.'X-Api-Key' = $GandiTokenInsecure
    }

    # get the zone name for our record
    $zoneName = Find-GandiZone $RecordName $RestHeaders
    Write-Debug "Found zone $zoneName"

    # find the matching TXT record if it exists
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if (-not $recShort) { $recShort = '@' }
    $recUrl = "https://dns.api.gandi.net/api/v5/domains/$zoneName/records/$recShort/TXT"
    try {
        $queryParams = @{
            Uri = $recUrl
            Headers = $RestHeaders
            ContentType = 'application/json'
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($queryParams.Uri)"
        $rec = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug "Response:`n$($rec | ConvertTo-Json)"
    } catch {}

    if ($rec -and "`"$TxtValue`"" -in $rec.rrset_values) {
        if ($rec.rrset_values.Count -gt 1) {
            # remove just the value we care about
            Write-Verbose "Removing $TxtValue from TXT record for $RecordName"
            $otherVals = $rec.rrset_values | Where-Object { $_ -ne "`"$TxtValue`"" }
            $queryParams = @{
                Method = 'PUT'
                Body = (@{rrset_values=@($otherVals)} | ConvertTo-Json -Compress)
            }
        } else {
            # delete the whole record because this value is the last one
            Write-Verbose "Removing TXT record for $RecordName"
            $queryParams = @{
                Method = 'DELETE'
            }
        }

        $queryParams.Uri = $recUrl
        $queryParams.Headers = $RestHeaders
        $queryParams.ContentType = 'application/json'
        $queryParams.Verbose = $false
        $queryParams.ErrorAction = 'Stop'
        try {
            Write-Debug "$($queryParams.Method) $($queryParams.Uri)`n$($queryParams.Body)"
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Gandi.

    .DESCRIPTION
        Remove a DNS TXT record from Gandi.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GandiToken
        The API token for your Gandi account.

    .PARAMETER GandiTokenInsecure
        (DEPRECATED) The API token for your Gandi account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Gandi Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes a TXT record using a securestring object for GandiToken. (Only works on Windows)
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
# https://doc.livedns.gandi.net

function Find-GandiZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestHeaders
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GandiRecordZones) { $script:GandiRecordZones = @{} }

    # check for the record in the cache
    if ($script:GandiRecordZones.ContainsKey($RecordName)) {
        return $script:GandiRecordZones.$RecordName
    }

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
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
        try {
            $queryParams = @{
                Uri = "https://dns.api.gandi.net/api/v5/domains/$zoneTest"
                Headers = $RestHeaders
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "GET $($queryParams.Uri)"
            $resp = Invoke-RestMethod @queryParams @script:UseBasic
            Write-Debug "Response:`n$($resp | ConvertTo-Json -Dep 10)"
            $script:GandiRecordZones.$RecordName = $zoneTest
            return $zoneTest
        } catch {
            if (404 -ne $_.Exception.Response.StatusCode) {
                throw
            }
        }
    }

    throw "Unable to find zone matching $RecordName"
}
