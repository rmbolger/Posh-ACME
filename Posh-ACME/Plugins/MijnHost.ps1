function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,

        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [securestring]$MijnHostApiKey,

        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$MijnHostApiKeyInsecure,

        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $MijnHostApiKeyInsecure = [PSCredential]::new('a', $MijnHostApiKey).GetNetworkCredential().Password
    }

    $restParams = Get-MijnHostRestParams -ApiKey $MijnHostApiKeyInsecure

    $zone = Find-MijnHostZone -RecordName $RecordName -RestParams $restParams
    if (-not $zone) { throw "Unable to find mijn.host zone for $RecordName" }

    # API requires a trailing dot on record names
    $fqdn = "$RecordName."

    # Fetch current records and check for an existing match (idempotent)
    $current = Invoke-MijnHostDnsGet -Zone $zone -RestParams $restParams
    $exists = $current | Where-Object { $_.type -eq 'TXT' -and $_.name -eq $fqdn -and $_.value -eq $TxtValue }

    if ($exists) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    Write-Verbose "Adding TXT record $fqdn on zone $zone"
    $newRecords = [array]$current + [PSCustomObject]@{ type = 'TXT'; name = $fqdn; value = $TxtValue; ttl = 900 }
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
    .PARAMETER MijnHostApiKeyInsecure
        (DEPRECATED) The API key for your mijn.host account as plain text.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -MijnHostApiKey $key
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,

        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [securestring]$MijnHostApiKey,

        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$MijnHostApiKeyInsecure,

        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $MijnHostApiKeyInsecure = [PSCredential]::new('a', $MijnHostApiKey).GetNetworkCredential().Password
    }

    $restParams = Get-MijnHostRestParams -ApiKey $MijnHostApiKeyInsecure

    $zone = Find-MijnHostZone -RecordName $RecordName -RestParams $restParams
    if (-not $zone) { throw "Unable to find mijn.host zone for $RecordName" }

    $fqdn = "$RecordName."
    $current = Invoke-MijnHostDnsGet -Zone $zone -RestParams $restParams
    $remaining = $current | Where-Object { -not ($_.type -eq 'TXT' -and $_.name -eq $fqdn -and $_.value -eq $TxtValue) }

    if ($current.Count -eq @($remaining).Count) {
        Write-Debug "Record $RecordName with value $TxtValue does not exist. Nothing to do."
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
    .PARAMETER MijnHostApiKeyInsecure
        (DEPRECATED) The API key for your mijn.host account as plain text.
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

    # Walk from longest to shortest label set, try each as a zone name.
    # Matches the strategy used by the official mijn.host certbot plugin.
    $pieces = $RecordName.Split('.')
    for ($i = 1; $i -lt $pieces.Count; $i++) {
        $zoneTest = ($pieces[$i..($pieces.Count - 1)]) -join '.'
        $url = "https://mijn.host/api/v2/domains/$zoneTest/dns"
        Write-Debug "Trying zone: $zoneTest"
        try {
            Invoke-RestMethod $url @RestParams -Method Get @script:UseBasic | Out-Null
            Write-Debug "Matched zone: $zoneTest"
            $script:MijnHostZoneCache.$RecordName = $zoneTest
            return $zoneTest
        } catch {
            $statusCode = try { $_.Exception.Response.StatusCode.value__ } catch { $null }
            if ($statusCode -eq 400 -or $statusCode -eq 404) {
                continue
            }
            throw
        }
    }

    return $null
}
