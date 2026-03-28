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
        [Parameter(Position=3)]
        [int]$DNSExitTTL = 0,
        [Parameter(Position=4)]
        [string]$DNSExitApiUri = 'https://api.dnsexit.com/dns/',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiKey = [pscredential]::new('a',$DNSExitApiKey).GetNetworkCredential().Password

    $queryParams = @{
        Uri = $DNSExitApiUri
        Method = 'POST'
        Headers = @{apikey=$apiKey}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
        Debug = $false
    }

    # The API has no GET endpoints to query available zones or existing records,
    # but adding a record requires knowing the zone name. So we're just going to
    # split the record name at various levels until one works or we run out
    # of combinations to try.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $shortName = ''
        if ($i -gt 0) { $shortName = $pieces[0..($i-1)] -join '.' }
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Trying name='$shortName' and domain='$zoneTest'"

        $queryParams.Body = @{
            domain = $zoneTest
            add = @{
                type = 'TXT'
                name = $shortName
                content = $TxtValue
                ttl = $DNSExitTTL
            }
        } | ConvertTo-Json -Depth 5 -Compress

        Write-Debug "POST $DNSExitApiUri`n$($queryParams.Body)"
        $resp = Invoke-RestMethod @queryParams @script:UseBasic
        if ($resp.code -eq 0) {
            Write-Debug "Successfully added record in zone '$zoneTest'"
            return
        } elseif ($resp.code -eq 6 -and $resp.message -like '*duplicate key value*') {
            Write-Debug "Record already exists in zone '$zoneTest'. Treating as success."
            return
        } else {
            Write-Debug "Failed to add record in zone '$zoneTest': $($resp.code) $($resp.message)"
        }
    }

    Write-Verbose "Failed to add TXT record $RecordName. Unable to find matching zone for API key."


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

    .PARAMETER DNSExitTTL
        The TTL for new TXT records in minutes. Defaults to 0.

    .PARAMETER DNSExitApiUri
        The DNSExit API endpoint URI.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $apiKey = Read-Host 'DNSExit API Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $apiKey

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
        [Parameter(Position=3)]
        [int]$DNSExitTTL = 0,
        [Parameter(Position=4)]
        [string]$DNSExitApiUri = 'https://api.dnsexit.com/dns/',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiKey = [pscredential]::new('a',$DNSExitApiKey).GetNetworkCredential().Password

    $queryParams = @{
        Uri = $DNSExitApiUri
        Method = 'POST'
        Headers = @{apikey=$apiKey}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
        Debug = $false
    }

    # The API has no GET endpoints to query available zones or existing records,
    # but adding a record requires knowing the zone name. So we're just going to
    # split the record name at various levels until one works or we run out
    # of combinations to try.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $shortName = ''
        if ($i -gt 0) { $shortName = $pieces[0..($i-1)] -join '.' }
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Trying name='$shortName' and domain='$zoneTest'"

        $queryParams.Body = @{
            domain = $zoneTest
            delete = @{
                type = 'TXT'
                name = $shortName
            }
        } | ConvertTo-Json -Depth 5 -Compress

        Write-Debug "POST $DNSExitApiUri`n$($queryParams.Body)"
        $resp = Invoke-RestMethod @queryParams @script:UseBasic
        if ($resp.code -eq 0) {
            Write-Debug "Successfully removed record in zone '$zoneTest'"
            return
        } else {
            Write-Debug "Failed to remove record in zone '$zoneTest': $($resp.code) $($resp.message)"
        }
    }

    Write-Verbose "Failed to remove TXT record $RecordName. Unable to find matching zone for API key."

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

    .PARAMETER DNSExitTTL
        Included for parameter parity with Add-DnsTxt. Not used during removal.

    .PARAMETER DNSExitApiUri
        The DNSExit API endpoint URI.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $apiKey = Read-Host 'DNSExit API Key' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $apiKey

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
