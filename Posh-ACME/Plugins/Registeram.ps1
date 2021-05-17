function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RegisteramServiceID,
        [Parameter(Mandatory, Position = 3)]
        [string]$RegisteramDomainID,
        [Parameter(Mandatory, Position = 4)]
        [string]$RegisteramAuthHash,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://www.registeram.com/ng/api/service/$RegisteramServiceID/dns/$RegisteramDomainID/records"

    # build the new record object
    $body = @{
        name     = $RecordName # Simply allows FQDNs here even though they return short names
        type     = 'TXT'
        data     = $TxtValue
        priority = 0
        ttl      = 600
    } | ConvertTo-Json

    Write-Debug "New Record body: `n$body"
    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

    try {
        $postParams = @{
            Uri         = $apiRoot
            Method      = 'POST'
            Body        = $body
            ContentType = 'application/json'
            Headers     = @{Authorization = "Bearer $RegisteramAuthHash" }
            ErrorAction = 'Stop'
        }
        Invoke-RestMethod @postParams @script:UseBasic | Out-Null
    }
    catch {
        Write-Debug $_
        throw
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Registeram.

    .DESCRIPTION
        Add a DNS TXT record to Registeram.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RegisteramServiceID
        The ServiceID for Registeram. Eg. 1234

    .PARAMETER RegisteramDomainID
        The DomainID for this particular Registeram domain Eg. 66
    
    .PARAMETER RegisteramAuthHash
        This is a BASE64 hash of your Registeram Credentials (username:password) Eg. am9obnNub3c6aXMtYS1kdW1iLWR1ZGU=

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'token' 1234 66 'am9obnNub3c6aXMtYS1kdW1iLWR1ZGU='

        Adds a TXT record for the specified site with the specified value.
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
        [string]$RegisteramServiceID,
        [Parameter(Mandatory, Position = 3)]
        [string]$RegisteramDomainID,
        [Parameter(Mandatory, Position = 4)]
        [string]$RegisteramAuthHash,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://www.registeram.com/ng/api/service/$RegisteramServiceID/dns/$RegisteramDomainID"

    $restParams = @{
        Headers     = @{Authorization = "Bearer $RegisteramAuthHash" }
        ContentType = 'application/json'
    }

    # get all the instances of the record
    try {
        $recs = (Invoke-RestMethod $apiRoot  @restParams @script:UseBasic).data
    }
    catch { throw }

    if ($recs.Count -eq 0 -or $TxtValue -notin $recs.content) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }
    else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $recID = ($recs | Where-Object { $_.content -eq $TxtValue }).id
            Invoke-RestMethod "$apiRoot/records/$recID" -Method Delete @restParams @script:UseBasic | Out-Null
        }
        catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Registeram.

    .DESCRIPTION
        Remove a DNS TXT record from Registeram.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RegisteramToken
        The Account API token for Registeram. This SecureString version should only be used on Windows.

    .PARAMETER RegisteramTokenInsecure
        The Account API token for Registeram. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Registeram Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes a TXT record for the specified site with the specified value on Windows.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'token'

        Remove a TXT record for the specified site with the specified value on non-Windows.
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
# https://developer.dnsimple.com/v2/

function Find-RegisteramZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$AcctID,
        [Parameter(Mandatory, Position = 2)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:RegisteramRecordZones) { $script:RegisteramRecordZones = @{} }

    # check for the record in the cache
    if ($script:RegisteramRecordZones.ContainsKey($RecordName)) {
        return $script:RegisteramRecordZones.$RecordName
    }

    $apiRoot = 'https://api.dnsimple.com/v2'

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            # if the call succeeds, the zone exists, so we don't care about the actualy response
            $null = Invoke-RestMethod "$apiRoot/$AcctID/zones/$zoneTest" @RestParams @script:UseBasic
            $script:RegisteramRecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
        catch {
            Write-Debug ($_.ToString())
        }
    }

    return $null

}
