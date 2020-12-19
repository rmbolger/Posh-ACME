function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,

        [Parameter(Mandatory, Position = 2)]
        [securestring]$MijnHostApiKey,

        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiKey = [PSCredential]::new('a', $MijnHostApiKey).GetNetworkCredential().Password
    $restParams = Get-MijnHostRestParams -ApiKey $apiKey

    $zone = Find-MijnHostZone -RecordName $RecordName -RestParams $restParams
    if (-not $zone) { throw "Unable to find mijn.host zone for $RecordName" }

    # API requires a trailing dot on record names
    $fqdn = "$RecordName."

    # The mijn.host API (PowerDNS) expects TXT values without surrounding quotes.
    # Posh-ACME passes dns-persist-01 TxtValues wrapped in double quotes, so strip them.
    $normalizedValue = $TxtValue -replace '^"(.*)"$', '$1'

    # Fetch current records and check for an existing match (idempotent)
    $current = Invoke-MijnHostDnsGet -Zone $zone -RestParams $restParams
    $exists = $current | Where-Object { $_.type -eq 'TXT' -and $_.name -eq $fqdn -and $_.value -eq $normalizedValue }

    if ($exists) {
        Write-Debug "Record $RecordName already contains $normalizedValue. Nothing to do."
        return
    }

    Write-Verbose "Adding TXT record $fqdn on zone $zone"
    $newRecords = [array]$current + [PSCustomObject]@{ type = 'TXT'; name = $fqdn; value = $normalizedValue; ttl = 900 }
    Invoke-MijnHostDnsPut -Zone $zone -Records $newRecords -RestParams $restParams

    <#
    .SYNOPSIS
        Add a DNS TXT record to mijn.host.
    .DESCRIPTION
        Uses the mijn.host API to add a DNS TXT record for ACME DNS-01 challenges.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER MijnHostApiKey
        The API key for your mijn.host account as a SecureString.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -MijnHostApiKey $key
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,

        [Parameter(Mandatory, Position = 2)]
        [securestring]$MijnHostApiKey,

        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiKey = [PSCredential]::new('a', $MijnHostApiKey).GetNetworkCredential().Password
    $restParams = Get-MijnHostRestParams -ApiKey $apiKey

    $zone = Find-MijnHostZone -RecordName $RecordName -RestParams $restParams
    if (-not $zone) { throw "Unable to find mijn.host zone for $RecordName" }

    $fqdn = "$RecordName."
    $normalizedValue = $TxtValue -replace '^"(.*)"$', '$1'

    $current = Invoke-MijnHostDnsGet -Zone $zone -RestParams $restParams
    $remaining = $current | Where-Object { -not ($_.type -eq 'TXT' -and $_.name -eq $fqdn -and $_.value -eq $normalizedValue) }

    if ($current.Count -eq @($remaining).Count) {
        Write-Debug "Record $RecordName with value $normalizedValue does not exist. Nothing to do."
        return
    }

    Write-Verbose "Removing TXT record $fqdn from zone $zone"
    Invoke-MijnHostDnsPut -Zone $zone -Records $remaining -RestParams $restParams

    <#
    .SYNOPSIS
        Remove a DNS TXT record from mijn.host.
    .DESCRIPTION
        Uses the mijn.host API to remove a DNS TXT record after ACME DNS-01 challenge completion.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER MijnHostApiKey
        The API key for your mijn.host account as a SecureString.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -MijnHostApiKey $key
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required for mijn.host.
    .DESCRIPTION
        mijn.host applies DNS changes immediately. No commit step is needed.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# API docs: https://mijn.host/api/doc

function Get-MijnHostRestParams {
    param (
        [string]$ApiKey
    )
    return @{
        Headers     = @{
            'API-Key' = $ApiKey
            'Accept'  = 'application/json'
        }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
}

function Invoke-MijnHostDnsGet {
    param (
        [string]$Zone,

        [hashtable]$RestParams
    )
    $url = "https://mijn.host/api/v2/domains/$Zone/dns"
    Write-Debug "GET $url"
    $response = Invoke-RestMethod $url @RestParams -Method Get @script:UseBasic
    return $response.data.records
}

function Invoke-MijnHostDnsPut {
    param (
        [string]$Zone,

        $Records,

        [hashtable]$RestParams
    )
    $url = "https://mijn.host/api/v2/domains/$Zone/dns"
    $body = @{ records = @($Records) } | ConvertTo-Json -Depth 10 -Compress
    Write-Debug "PUT $url`n$body"
    Invoke-RestMethod $url @RestParams -Method Put -Body $body @script:UseBasic | Out-Null
}

function Find-MijnHostZone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [hashtable]$RestParams
    )

    if (!$script:MijnHostZoneCache) { $script:MijnHostZoneCache = @{} }

    if ($script:MijnHostZoneCache.ContainsKey($RecordName)) {
        return $script:MijnHostZoneCache.$RecordName
    }

    # Fetch the list of zones the API key can manage, then find the longest
    # suffix of RecordName that matches a known zone. Using the domains list
    # avoids per-zone probe requests and correctly handles the domain apex case
    # (where the record name itself is the zone, e.g. when using -DnsAlias).
    $url = "https://mijn.host/api/v2/domains"
    Write-Debug "GET $url"
    $response = Invoke-RestMethod $url @RestParams -Method Get @script:UseBasic
    $zones = $response.data.domains | Select-Object -ExpandProperty domain

    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt $pieces.Count; $i++) {
        $zone = ($pieces[$i..($pieces.Count - 1)]) -join '.'
        if ($zone -in $zones) {
            Write-Debug "Matched zone: $zone"
            $script:MijnHostZoneCache.$RecordName = $zone
            return $zone
        }
    }

    return $null
}
