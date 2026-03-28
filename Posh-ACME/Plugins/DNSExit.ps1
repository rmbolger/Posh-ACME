function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$DNSExitApiKey,
        [Parameter(Mandatory,Position=3)]
        [string[]]$DNSExitDomain,
        [Parameter(Position=4)]
        [int]$DNSExitTTL = 0,
        [Parameter(Position=5)]
        [string]$DNSExitApiUri = 'https://api.dnsexit.com/dns/',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiKey = [pscredential]::new('a',$DNSExitApiKey).GetNetworkCredential().Password
    $zoneName = Find-DNSExitZone $RecordName $DNSExitDomain
    $recShort = Get-DNSExitRelativeName $RecordName $zoneName

    $payload = @{
        domain = $zoneName
        add = @{
            type = 'TXT'
            name = $recShort
            content = $TxtValue
            ttl = $DNSExitTTL
        }
    }

    Write-Verbose "Adding TXT record $RecordName in zone $zoneName"
    Invoke-DNSExitApi $DNSExitApiUri $apiKey $payload | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record to DNSExit.

    .DESCRIPTION
        Uses the DNSExit DNS JSON API to add an ACME DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSExitApiKey
        The DNSExit DNS API key associated with your account.

    .PARAMETER DNSExitDomain
        One or more DNS zones hosted in DNSExit. The deepest matching zone is used for a record.

    .PARAMETER DNSExitTTL
        The TTL for new TXT records in minutes. Defaults to 0.

    .PARAMETER DNSExitApiUri
        The DNSExit API endpoint URI.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $apiKey = Read-Host 'DNSExit API Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $apiKey 'example.com'

        Adds the specified TXT record using the DNSExit API.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$DNSExitApiKey,
        [Parameter(Mandatory,Position=3)]
        [string[]]$DNSExitDomain,
        [Parameter(Position=4)]
        [int]$DNSExitTTL = 0,
        [Parameter(Position=5)]
        [string]$DNSExitApiUri = 'https://api.dnsexit.com/dns/',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiKey = [pscredential]::new('a',$DNSExitApiKey).GetNetworkCredential().Password
    $zoneName = Find-DNSExitZone $RecordName $DNSExitDomain
    $recShort = Get-DNSExitRelativeName $RecordName $zoneName

    # DNSExit's public docs only demonstrate delete operations by name rather
    # than by TXT content. We include content because it may be accepted by the
    # API, but callers should treat name-scoped deletion as the documented
    # provider behavior.
    $payload = @{
        domain = $zoneName
        delete = @{
            type = 'TXT'
            name = $recShort
            content = $TxtValue
        }
    }

    Write-Verbose "Removing TXT record $RecordName from zone $zoneName"
    Invoke-DNSExitApi $DNSExitApiUri $apiKey $payload | Out-Null

    <#
    .SYNOPSIS
        Remove a DNS TXT record from DNSExit.

    .DESCRIPTION
        Uses the DNSExit DNS JSON API to remove an ACME DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSExitApiKey
        The DNSExit DNS API key associated with your account.

    .PARAMETER DNSExitDomain
        One or more DNS zones hosted in DNSExit. The deepest matching zone is used for a record.

    .PARAMETER DNSExitTTL
        Included for parameter parity with Add-DnsTxt. Not used during removal.

    .PARAMETER DNSExitApiUri
        The DNSExit API endpoint URI.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $apiKey = Read-Host 'DNSExit API Key' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $apiKey 'example.com'

        Removes the specified TXT record using the DNSExit API.
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

# API Docs:
# https://dnsexit.com/dns/dns-api/

function Find-DNSExitZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string[]]$DNSExitDomain
    )

    $zones = @($DNSExitDomain | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
        $_.Trim().TrimEnd('.')
    } | Sort-Object -Unique)

    $pieces = $RecordName.TrimEnd('.').Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        if ($zoneTest -in $zones) {
            Write-Debug "Matched DNSExit zone $zoneTest for record $RecordName"
            return $zoneTest
        }
    }

    throw "Unable to find a matching DNSExit zone for $RecordName. Supply the hosted zone using DNSExitDomain."
}

function Get-DNSExitRelativeName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ZoneName
    )

    $recShort = $RecordName.TrimEnd('.') -ireplace "\.?$([regex]::Escape($ZoneName.TrimEnd('.')))$",''
    Write-Debug "Using relative record name '$recShort' in zone '$ZoneName'"
    return $recShort
}

function Invoke-DNSExitApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ApiUri,
        [Parameter(Mandatory,Position=1)]
        [string]$ApiKey,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$Payload
    )

    $body = $Payload | ConvertTo-Json -Depth 5 -Compress
    $headers = @{
        'Content-Type' = 'application/json'
        'apikey' = $ApiKey
    }
    $safeHeaders = @{
        'Content-Type' = 'application/json'
        'apikey' = 'REDACTED'
    }

    Write-Debug "POST $ApiUri`nHeaders: $($safeHeaders | ConvertTo-Json -Compress)`nBody: $body"

    try {
        $result = Invoke-RestMethod -Uri $ApiUri -Method Post -Headers $headers -Body $body -ErrorAction Stop @script:UseBasic
    } catch {
        throw
    }

    if ($null -eq $result) {
        throw 'DNSExit API returned an empty response.'
    }

    if ($result.code -ne 0) {
        throw "DNSExit API returned code $($result.code): $($result.message)"
    }

    return $result
}
