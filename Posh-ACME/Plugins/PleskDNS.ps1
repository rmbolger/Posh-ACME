function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$PleskUrl,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [AllowNull()]
        [securestring]$PleskToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [AllowEmptyString()]
        [string]$PleskTokenInsecure,
        [int]$Ttl=1800,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    <#
    .SYNOPSIS
        Add a DNS TXT record to Plesk

    .DESCRIPTION
        Add a DNS TXT record to Plesk

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PleskUrl
        The Plesk base url

    .PARAMETER PleskToken
        The Plesk API key

    .PARAMETER Ttl
        Time to live of the DNS records. Default is 1800 seconds

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -PleskUrl 'https://plesk01.example.com:8443' -PleskToken (ConvertTo-SecureString '78711059-23bb-cf6f-b07f-985e1995d2e2' -AsPlainText)

        Adds a TXT record for the specified zone with the specified name and value.
    #>

    try { 
        $tokenParams = @{}
        if ($PSBoundParameters.ContainsKey('PleskToken'))         { $tokenParams.PleskToken         = $PleskToken }
        if ($PSBoundParameters.ContainsKey('PleskTokenInsecure')) { $tokenParams.PleskTokenInsecure = $PleskTokenInsecure }
        $headers = Get-PleskHeaders @tokenParams
    } catch { throw }

    try { $rec = Get-PleskDnsTxtRecord $RecordName $TxtValue -PleskUrl $PleskUrl -Headers $headers } catch { throw }
    if ($rec) {
        Write-Verbose "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    $pleskZone = Find-PleskDnsZone $RecordName -PleskUrl $PleskUrl -Headers $headers

    $url = "{0}/api/v2/dns/records?domain={1}" -f $PleskUrl.TrimEnd('/'), $pleskZone
    $body = @{
        type  = "TXT"
        host  = $RecordName
        value = $TxtValue
        ttl   = $Ttl
    } | ConvertTo-Json

    $resp = Invoke-RestMethod -Method POST -Uri $url -ContentType 'application/json' -Body $body -Headers $headers @script:UseBasic

    Write-Verbose ("Created TXT id={0} host={1} value={2}" -f $resp.id, $resp.host, $resp.value)
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$PleskUrl,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [AllowNull()]
        [securestring]$PleskToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [AllowEmptyString()]
        [string]$PleskTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Removes a DNS TXT record from Plesk

    .DESCRIPTION
        Removes a DNS TXT record from Plesk

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER PleskUrl
        The Plesk base url

    .PARAMETER PleskToken
        The Plesk API key. Check the Plesk documentation for further information.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -PleskUrl 'https://plesk01.example.com:8443' -PleskToken (ConvertTo-SecureString '78711059-23bb-cf6f-b07f-985e1995d2e2' -AsPlainText)

        Removes a TXT record for the specified zone with the specified name and value.
    #>

    try { 
        $tokenParams = @{}
        if ($PSBoundParameters.ContainsKey('PleskToken'))         { $tokenParams.PleskToken         = $PleskToken }
        if ($PSBoundParameters.ContainsKey('PleskTokenInsecure')) { $tokenParams.PleskTokenInsecure = $PleskTokenInsecure }
        $headers = Get-PleskHeaders @tokenParams
    } catch { throw }

    try {$recordsToDelete = Get-PleskDnsTxtRecord $RecordName $TxtValue -PleskUrl $PleskUrl -Headers $headers} catch { throw }
    if ($recordsToDelete.Count -eq 0) {
      Write-Verbose "No record $RecordName with value $TxtValue exists. Nothing to do."
      return
    }

    $recordsToDelete | ForEach-Object {
      $url = "{0}/api/v2/dns/records/{1}" -f $PleskUrl.TrimEnd('/'), $_.id
      try {
        $resp = Invoke-RestMethod -Method DELETE -Uri $url -ContentType 'application/json' -Headers $headers @script:UseBasic
        if ($resp -and $resp.status) {
          Write-Verbose ("Deleted TXT id={0} host={1} value={2} (status={3})" -f $_.id, $_.host, $_.value, $resp.status)
        }
      } catch {
        throw "Failed to delete record id=$($_.id): $($_.Exception.Message)"
      }
    }
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

# Plesk Rest-API Documentation
# https://docs.plesk.com/en-US/obsidian/api-rpc/about-rest-api.79359/

function Find-PleskDnsZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory)]
        [string]$PleskUrl,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$headers
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:PleskDnsRecordZones) { $script:PleskDnsRecordZones = @{} }

    # check for the record in the cache
    if ($script:PleskDnsRecordZones.ContainsKey($RecordName)) {
        return $script:PleskDnsRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        $url = "{0}/api/v2/dns/records?domain={1}" -f $PleskUrl.TrimEnd('/'), $zoneTest
        try {
          $resp = Invoke-RestMethod -Method GET -Uri $url -ContentType 'application/json' -Headers $headers @script:UseBasic

          Write-Debug "Found zone $zoneTest"
          $script:PleskDnsRecordZones.$RecordName = $zoneTest
          return $zoneTest
        } catch {
          Write-Debug "No zone found for $zoneTest with url $url"
          continue
        }
    }

    throw "No zone found for $RecordName"
}

function Get-PleskDnsTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$PleskUrl,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$headers
    )

    $pleskZone = Find-PleskDnsZone $RecordName -PleskUrl $PleskUrl -Headers $headers

    $url = "{0}/api/v2/dns/records?domain={1}" -f $PleskUrl.TrimEnd('/'), $pleskZone

    $resp = Invoke-RestMethod -Method GET -Uri $url -ContentType 'application/json' -Headers $headers @script:UseBasic
    $records = @($resp)

    $matches = $records | Where-Object {
      $_.type -eq 'TXT' -and 
      $_.host -eq ($RecordName + '.') -and
      $_.value -eq $TxtValue
    }

    Write-Verbose ("Found {0} TXT record(s)." -f @($matches).Count)

    return ,$matches  # return as array even if 0/1 item
}

function Get-PleskHeaders {
    param(
        [Parameter(ParameterSetName='Secure',Mandatory,Position=0)]
        [securestring]$PleskToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=0)]
        [string]$PleskTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $PleskTokenInsecure = [pscredential]::new('a',$PleskToken).GetNetworkCredential().Password
    }

    return @{ 'X-API-Key' = $PleskTokenInsecure }
}