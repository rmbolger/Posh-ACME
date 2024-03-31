function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [pscredential]$WskCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zoneName,$zoneID,$zoneRecs = Find-Zone $RecordName $WskCredential

    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if (-not $recShort) { $recShort = '@' }

    # get all the instances of the record
    $rec = $zoneRecs | Where-Object { $_.name -eq $RecordName -and $_.type -eq 'TXT' -and $_.content -eq $TxtValue }

    if (-not $rec) {
        # add new record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $bodyJson = @{
            name = $recShort
            type = 'TXT'
            content = $TxtValue
            ttl = 60
        } | ConvertTo-Json -Compress
        $restArgs = @{
            Path = "/v2/service/$zoneID/dns/record"
            Method = 'POST'
            Credential = $WskCredential
            Body = $bodyJson
        }
        Invoke-WSKRest @restArgs | Out-Null
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Websupport.sk.

    .DESCRIPTION
        Add a DNS TXT record to Websupport.sk

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER WskCredential
        A PSCredential object that has the API Key as the username and Secret as the password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $cred 123456

        Adds a TXT record for the specified site with the specified value on Windows.
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
        [pscredential]$WskCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zoneName,$zoneID,$zoneRecs = Find-Zone $RecordName $WskCredential

    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if (-not $recShort) { $recShort = '@' }

    # get all the instances of the record
    $rec = $zoneRecs | Where-Object { $_.name -eq $RecordName -and $_.type -eq 'TXT' -and $_.content -eq $TxtValue }

    if (-not $rec) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        $restArgs = @{
            Path = "/v2/service/$zoneID/dns/record/$($rec.id)"
            Method = 'DELETE'
            Credential = $WskCredential
        }
        Invoke-WSKRest @restArgs | Out-Null
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Websupport.sk.

    .DESCRIPTION
        Remove a DNS TXT record from Websupport.sk.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER WskCredential
        A PSCredential object that has the API Key as the username and Secret as the password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $cred 123456

        Removes a TXT record for the specified site with the specified value on Windows.
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
# https://rest.websupport.sk/v2/docs/intro
# https://rest.websupport.sk/v2/docs
# https://rest.websupport.sk/docs/v1.intro
# https://rest.websupport.sk/docs/v1.zone#zones

function Invoke-WSKRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Path,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$Credential,
        [string]$Method = 'GET',
        [string]$Query,
        [string]$Body
    )

    # grab the plaintext secret from the credential password
    $apiSecret = $Credential.GetNetworkCredential().Password

    # Build the canonical request
    $now = [DateTimeOffset]::UtcNow
    $req = '{0} {1} {2}' -f $Method.ToUpper(),$Path,$now.ToUnixTimeSeconds()
    Write-Debug "Canonical Request: $req"

    # Sign the request with the API secret as the key
    $keyBytes = [Text.Encoding]::ASCII.GetBytes($apiSecret)
    $hmacsha = [Security.Cryptography.HMACSHA1]::new($keyBytes)
    $sigBytes = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($req))
    $sig = ($sigBytes | ForEach-Object { $_.ToString('x2') }) -join ''
    Write-Debug "Signature: $sig"

    # Build a Basic Auth header using the API Key as the username and the
    # signature as the password
    $credPlain = '{0}:{1}' -f $Credential.Username,$sig
    $credB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($credPlain))
    $auth = "Basic $credB64"

    # And finally build the REST query
    $queryParams = @{
        Uri = 'https://rest.websupport.sk{0}{1}' -f $Path,$Query
        Method = $Method.ToUpper()
        Headers = @{
            Authorization = $auth
            Accept = "application/json"
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }
    Write-Debug "$($queryParams.Method) $($queryParams.Uri)"

    # 'X-Date' header is required for v2 endpoints but 'Date' is required for v1
    # endpoints. So this conditional will be required until v2 is fleshed out enough
    # that we can stop using v1.
    if ($Path -like '/v1*') {
        $queryParams.Headers.'Date' = $now.ToString('yyyy-MM-ddTHH:mm:ssZ')
        # The v1 API requires this header be in ISO8601 format. But that's not the
        # format it's supposed to be according to the HTTP spec.
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
        #
        # PowerShell 7 does header validation by default now and rejects the request
        # unless you specify the SkipHeaderValidation flag.
        if ('SkipHeaderValidation' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
            $queryParams.SkipHeaderValidation = $true
        }
    } else {
        $queryParams.Headers.'X-Date' = $now.ToString('yyyy-MM-ddTHH:mm:ssZ')
    }

    if ($Body) {
        $queryParams.ContentType = 'application/json'
        $queryParams.Body = $Body
        Write-Debug "Body:`n$Body"
    }

    try {
        Invoke-RestMethod @queryParams @script:UseBasic
    } catch {
        throw
    }
}

function Get-WskZoneRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [pscredential]$Credential,
        [Parameter(Mandatory,Position=1)]
        [string]$ServiceId
    )

    # While this API does support filtering record queries, you can only
    # do so by supplying the filter arguments as a JSON body in a GET request
    # and PowerShell 5.1 doesn't allow sending a body with a GET request.
    #
    # So instead, we need to avoid all filters and page through all of the
    # results to then filter locally.

    $restArgs = @{
        Path = "/v2/service/$ServiceId/dns/record"
        Credential = $Credential
        Query = "?rowsPerPage=50"
    }
    $resp = Invoke-WSKRest @restArgs
    $recs = $resp.data
    while ($resp.nextPageUrl) {
        $restArgs.Query = $resp.nextPageUrl.TrimStart('/')
        $resp = Invoke-WSKRest @restArgs
        $recs += $resp.data
    }

    return $recs
}

function Find-Zone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$Credential
    )

    # Use the v1 API to get the list of available zones and IDs
    $zones = Invoke-WSKRest -Path /v1/user/self/zone -Credential $Credential |
        Select-Object -Expand items

    foreach ($zone in $zones) {
        if ($RecordName -like "*$($zone.name)") {
            $allrecs = Get-WskZoneRecords $Credential $zone.id

            return $zone.name,$zone.id,$allrecs
        }
    }

    throw "Unable to find matching zone for $RecordName"
}
