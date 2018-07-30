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

    $RecordName = $RecordName.ToLower()

    $token = Get-DynuAccessToken -DynuClientID $DynuClientID -DynuSecret $DynuSecret
    $zone = Find-DynuZone $RecordName -DynuAccessToken $token
    if (-not $zone) {
        throw "Could not find Dynu zone that matches ${RecordName}"
    }

    # Strip the domain if it is on the suffix
    if ($RecordName.EndsWith(".$($zone.name)")) {
        $RecordName = $RecordName.Substring(0, $RecordName.LastIndexOf(".$($zone.name)"))
    }

    $existing = Find-DynuExistingRecord $zone.name $RecordName $TxtValue -DynuAccessToken $token
    if ($existing) {
        Write-Debug "Record already exists, doing nothing: ${existing}"
        return
    }

    $body = ConvertTo-Json @{
        domain_name = $zone.name
        node_name = $RecordName
        record_type = "TXT"
        text_data = $TxtValue
        state = "true"
    }
    try {
        $response = Invoke-RestMethod -Method "Post" -Uri "https://api.dynu.com/v1/dns/record/add" `
            -Headers @{Authorization = "Bearer ${token}"} -ContentType "application/json" `
            -Body $body @script:UseBasic
        if (-not $response.id) {
            throw "Record creation failed: ${response}"
        }
    } catch {
        throw
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
    $RecordName = $RecordName.ToLower()

    $token = Get-DynuAccessToken -DynuClientID $DynuClientID -DynuSecret $DynuSecret
    $zone = Find-DynuZone $RecordName -DynuAccessToken $token
    if (-not $zone) {
        throw "Could not find Dynu zone that matches ${RecordName}"
    }

    # Strip the domain if it is on the suffix
    if ($RecordName.EndsWith(".$($zone.name)")) {
        $RecordName = $RecordName.Substring(0, $RecordName.LastIndexOf(".$($zone.name)"))
    }

    $record = Find-DynuExistingRecord $zone.name $RecordName $TxtValue -DynuAccessToken $token
    if (-not $record) {
        Write-Debug "Record ${RecordName}/${TxtValue} doesn't exist, doing nothing"
        return
    }

    Write-Debug "Removing ${record}"
    try {
        $response = Invoke-RestMethod -Method "Get" -Uri "https://api.dynu.com/v1/dns/record/delete/$($record.id)" `
            -Headers @{Authorization = "Bearer ${token}"} @script:UseBasic
        if ($response -ne $true) {
            throw "Record deletion failed: ${response}"
        }
    } catch {
        throw
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
        Accept = "application/json"
        "Content-Type" = "application/x-www-form-urlencoded"
        "Authorization" = "Basic ${encodedCreds}"
    }

    try {
        $response = Invoke-RestMethod -Method 'Post' -Uri "https://api.dynu.com/v1/oauth2/token" `
            -Body "grant_type=client_credentials" -Headers $headers @script:UseBasic
    } catch {
        throw
    }

    if (-not $response.accessToken) {
        throw "Could not get an access token for Dynu"
    }

    $script:DynuAccessToken = @{
        AccessToken = $response.accessToken
        Expiry = (Get-DateTimeOffsetNow).AddSeconds($response.expiresIn - 300)
    }

    return $script:DynuAccessToken.AccessToken
}

function Find-DynuZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$DynuAccessToken
    )

    try {
        $zones = Invoke-RestMethod -Method "Get" -Uri "https://api.dynu.com/v1/dns/domains" `
            -Headers @{Accept = "application/json"; Authorization = "Bearer ${DynuAccessToken}"} `
            @script:UseBasic
    } catch {
        throw
    }

    $pieces = $RecordName.Split('.')
    for ($i = 1; $i -lt ($pieces.Count - 1); $i++) {
        $zone = $zones | Where-Object { $_.name -eq "$( $pieces[$i..($pieces.Count-1)] -join '.' )" }
        if ($zone) {
            return $zone
        }
    }

    return $null
}

function Find-DynuExistingRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ZoneName,
        [Parameter(Mandatory, Position = 1)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 2)]
        [string]$RecordValue,
        [Parameter(Mandatory, Position = 3)]
        [string]$DynuAccessToken
    )

    try {
        $records = Invoke-RestMethod -Method "Get" -Uri "https://api.dynu.com/v1/dns/records/${ZoneName}" `
            -Headers @{Authorization = "Bearer ${DynuAccessToken}"} @script:UseBasic
    } catch {
        throw
    }

    return $records | Where-Object { ($_.node_name -eq $RecordName -and $_.content -eq $RecordValue )} | Select-Object -First 1
}
