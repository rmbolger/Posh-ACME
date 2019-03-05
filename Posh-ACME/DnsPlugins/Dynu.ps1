function Add-DnsTxtDynu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DynuClientID,
        [Parameter(Mandatory,Position=3)]
        [string]$DynuSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiBase = 'https://api.dynu.com/v2'
    $RecordName = $RecordName.ToLower()

    # authenticate
    $token = Get-DynuAccessToken $DynuClientID $DynuSecret
    $headers = @{
        Accept = 'application/json'
        Authorization = "Bearer $token"
    }

    # The v2 API has a super convenient method for querying a record entirely based on hostname
    # so we don't have to deal with the typical find zone id rigamarole.
    try {
        $response = Invoke-RestMethod "$apiBase/dns/record/$($RecordName)?recordType=TXT" `
            -Headers $headers @script:UseBasic
    } catch { throw }

    if ($response.dnsRecords -and $TxtValue -in $response.dnsRecords.textData) {
        # nothing to do
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # if there's at least one record in the response, we can get the zone ID from it, otherwise
        # we need to query for the zone ID in before we can add the new record
        if ($response.dnsRecords.Count -gt 0) {
            $zoneID = $response.dnsRecords[0].domainId
            $recNode = $response.dnsRecords[0].nodeName
        } else {
            # query the zone info
            try {
                $zoneResp = Invoke-RestMethod "$apiBase/dns/getroot/$RecordName" `
                    -Headers $headers @script:UseBasic
            } catch { throw }

            if ($zoneResp -and $zoneResp.id) {
                $zoneID = $zoneResp.id
                $recNode = $zoneResp.node
            } else {
                throw "No zone info returned for $RecordName from Dynu"
            }
        }

        # now that we have the zone ID, we can add the new record
        $bodyJson = @{
            nodeName = $recNode
            recordType = 'TXT'
            textData = $TxtValue
            state = $true
        } | ConvertTo-Json -Compress
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            Invoke-RestMethod "$apiBase/dns/$zoneID/record" -Method Post -Body $bodyJson `
                -Headers $headers -ContentType 'application/json' @script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Dynu

    .DESCRIPTION
        Adds the TXT record to the Dynu zone

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DynuClientID
        The API Client ID for the Dynu account. Can be found at https://www.dynu.com/en-US/ControlPanel/APICredentials

    .PARAMETER DynuSecret
        The API Secret for the Dynu account. Can be found at https://www.dynu.com/en-US/ControlPanel/APICredentials

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtDynu '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dynu_api_client_id' 'dynu_api_client_secret'

        Adds a TXT record for the specified domain with the specified value.
    #>
}

function Remove-DnsTxtDynu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DynuClientID,
        [Parameter(Mandatory,Position=3)]
        [string]$DynuSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiBase = 'https://api.dynu.com/v2'
    $RecordName = $RecordName.ToLower()

    # authenticate
    $token = Get-DynuAccessToken $DynuClientID $DynuSecret
    $headers = @{
        Accept = 'application/json'
        Authorization = "Bearer $token"
    }

    # The v2 API has a super convenient method for querying a record entirely based on hostname
    # so we don't have to deal with the typical find zone id rigamarole.
    try {
        $response = Invoke-RestMethod "$apiBase/dns/record/$($RecordName)?recordType=TXT" `
            -Headers $headers @script:UseBasic
    } catch { throw }

    if ($response.dnsRecords -and $TxtValue -in $response.dnsRecords.textData) {
        # grab the record and delete it
        $rec = $response.dnsRecords | Where-Object { $_.textData -eq $TxtValue }
        try {
            Write-Verbose "Deleting $RecordName with value $TxtValue"
            Invoke-RestMethod "$apiBase/dns/$($rec.domainId)/record/$($rec.id)" -Method Delete `
                -Headers $headers @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        # nothing to do
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Dynu

    .DESCRIPTION
        Removes the TXT record from the Dynu zone

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DynuClientID
        The API Client ID for the Dynu account. Can be found at https://www.dynu.com/en-US/ControlPanel/APICredentials

    .PARAMETER DynuSecret
        The API Secret for the Dynu account. Can be found at https://www.dynu.com/en-US/ControlPanel/APICredentials

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtDynu '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dynu_api_client_id' 'dynu_api_client_secret'

        Removes a TXT record for the specified domain with the specified value.
    #>
}

function Save-DnsTxtDynu {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required

    .DESCRIPTION
        This provider does not require calling this function to save DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://www.dynu.com/en-US/Resources/API

function Get-DynuAccessToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$DynuClientID,
        [Parameter(Mandatory, Position = 1)]
        [string]$DynuSecret
    )

    if ($script:DynuAccessToken -and ($script:DynuAccessToken.Expiry -lt (Get-DateTimeOffsetNow))) {
        return $script:DynuAccessToken.AccessToken
    }

    # Dynu's web server requires the credentials to be passed on the first call, so we can't just
    # use the -Credential parameter because it only adds credentials after passing nothing and getting
    # an auth challenge response.
    $encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${DynuClientID}:${DynuSecret}"))
    $headers = @{
        Accept = 'application/json'
        Authorization = "Basic $encodedCreds"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.dynu.com/v2/oauth2/token" -Headers $headers @script:UseBasic
    } catch {
        throw
    }

    if (-not $response.access_token) {
        Write-Debug ($response | ConvertTo-Json)
        throw "Access token not found in OAuth2 response from Dynu"
    }

    $script:DynuAccessToken = @{
        AccessToken = $response.access_token
        Expiry = (Get-DateTimeOffsetNow).AddSeconds($response.expires_in - 300)
    }

    return $script:DynuAccessToken.AccessToken
}
