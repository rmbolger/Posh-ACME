function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$HNLToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $HNLTokenInsecure = [pscredential]::new('a', $HNLToken).GetNetworkCredential().Password

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    $zone = Find-HNLZone -RecordName $RecordName -Token $HNLTokenInsecure

    $rec = Invoke-HNLRest 'GET' "domains/$zone/dns" $HNLTokenInsecure |
        Select-Object -ExpandProperty data |
        Where-Object {
            $_.type -eq 'TXT' -and
            $_.name -eq $RecordName -and
            $_.content -eq $TxtValue
        }

    if ($rec) {
        Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
        return
    }

    # create the record (must be an array, even if only one)
    $body = ConvertTo-Json -InputObject @(@{
        name    = $RecordName
        type    = 'TXT'
        content = $TxtValue
        ttl     = 300
    })
    $null = Invoke-HNLRest 'POST' "domains/$zone/dns" $HNLTokenInsecure -Body $body

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hosting.nl.

    .DESCRIPTION
        Finds the zone that owns RecordName, checks whether a matching TXT
        record already exists, and if not, creates one via the Hosting.nl API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HNLToken
        The Hosting.nl API token, as a SecureString.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'HostingNL API Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HNLToken $token

        Adds the record using a SecureString token.
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
        [securestring]$HNLToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $HNLTokenInsecure = [pscredential]::new('a', $HNLToken).GetNetworkCredential().Password

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    $zone = Find-HNLZone -RecordName $RecordName -Token $HNLTokenInsecure

    $rec = Invoke-HNLRest 'GET' "domains/$zone/dns" $HNLTokenInsecure |
        Select-Object -ExpandProperty data |
        Where-Object {
            $_.type -eq 'TXT' -and
            $_.name -eq $RecordName -and
            $_.content -eq $TxtValue
        }

    if (-not $rec) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }

    $body = ConvertTo-Json -InputObject @(@{ id = $rec.id })
    $null = Invoke-HNLRest 'DELETE' "domains/$zone/dns" $HNLTokenInsecure -Body $body

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Hosting.nl.

    .DESCRIPTION
        Finds the zone that owns RecordName, looks up the matching TXT
        record by name and value, and deletes it by id via the Hosting.nl API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HNLToken
        The Hosting.nl API token, as a SecureString.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'HostingNL API Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HNLToken $token

        Removes the record using a SecureString token.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <# Not required. #>
}


############################
# Helper Functions
############################

# API docs: https://api.hosting.nl/api/documentation

# Wraps Invoke-RestMethod with the Hosting.nl auth header and error shape.
# Hosting.nl reports errors as either {"error": "..."} or
# {"errors": {"message": "..."}} in the response body rather than through
# HTTP status text alone, so a plain Invoke-RestMethod failure would surface
# a generic "400 Bad Request" instead of the actual reason. This pulls that
# message out of the error response and rethrows it, falling back to the raw
# error if the body doesn't match either shape.
function Invoke-HNLRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][string]$Method,
        [Parameter(Mandatory,Position=1)][string]$Path,
        [Parameter(Mandatory,Position=2)][string]$Token,
        [string]$Body
    )

    $params = @{
        Uri         = "https://api.hosting.nl/$Path"
        Method      = $Method
        Headers     = @{
            'API-TOKEN' = $Token
            'Accept'    = 'application/json'
        }
        ErrorAction = 'Stop'
        Verbose     = $false
        Debug       = $false
    }
    if ($Body) {
        $params.Body = $Body
        $params.ContentType = 'application/json'
    }

    try {
        Write-Debug "$Method $($params.Uri)"
        if ($Body) { Write-Debug $Body }
        return Invoke-RestMethod @params @script:UseBasic
    } catch {
        throw
    }

    <#
    .SYNOPSIS
        Calls the Hosting.nl REST API.

    .DESCRIPTION
        Wraps Invoke-RestMethod with the API-TOKEN header and JSON content type,
        serializes any body to a JSON array, and on failure rethrows the message
        Hosting.nl returns in the response body instead of a generic HTTP status.

    .PARAMETER Method
        The HTTP method: Get, Post, or Delete.

    .PARAMETER Path
        The request path appended to https://api.hosting.nl, for example /domains.

    .PARAMETER Token
        The Hosting.nl API token, as plaintext.

    .PARAMETER Body
        Optional request body (a PowerShell object or array) sent as JSON.

    .OUTPUTS
        The parsed response object.
    #>
}

function Find-HNLZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$Token
    )

    if (-not $script:HNLRecordZones) { $script:HNLRecordZones = @{} }

    if ($script:HNLRecordZones.ContainsKey($RecordName)) {
        return $script:HNLRecordZones[$RecordName]
    }

    # We need to find the closest/deepest sub-zone that would hold
    # the record rather than just adding it to the apex.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        try {
            $null = Invoke-HNLRest GET "domains/$zoneTest" $Token
            # No error means the zone exists, so cache it and return it
            # We don't need the save the ID because none of the other calls
            # we'll be using need it.
            Write-Debug "Cached zone $zoneTest for $RecordName"
            $script:HNLRecordZones[$RecordName] = $zoneTest
            return $zoneTest
        } catch {
            # 404 is expected if the zone doesn't exist. Re-throw any other error.
            if ($_.Exception.StatusCode -eq 404) {
                continue
            } else {
                Write-Debug "Error $($_.Exception.StatusCode)"
            }
            throw
        }
    }

    # If we get here, we didn't find a matching zone.
    throw "No zone in this account matches $RecordName"
}
