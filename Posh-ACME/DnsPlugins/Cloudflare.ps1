function Add-DnsTxtCloudflare {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$CFAuthEmail,
        [Parameter(Mandatory,Position=3)]
        [string]$CFAuthKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = @{'X-Auth-Email'=$CFAuthEmail;'X-Auth-Key'=$CFAuthKey}

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-CFZone $RecordName $CFAuthEmail $CFAuthKey)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    $response = Invoke-RestMethod "$apiRoot/$zoneID/dns_records?type=TXT&name=$RecordName&content=$TxtValue" `
        -Headers $authHeader -ContentType 'application/json' @script:UseBasic

    # add the new TXT record if necessary
    if ($response.result.Count -eq 0) {

        $bodyJson = @{ type="TXT"; name=$RecordName; content=$TxtValue } | ConvertTo-Json
        Write-Verbose "Adding $RecordName with value $TxtValue"
        Invoke-RestMethod "$apiRoot/$zoneID/dns_records" -Method Post -Body $bodyJson `
            -ContentType 'application/json' -Headers $authHeader @script:UseBasic | Out-Null

    } else {
        Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Cloudflare.

    .DESCRIPTION
        Use Cloudflare V4 api to add a TXT record to a Cloudflare DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CFAuthEmail
        The email address of the account used to connect to Cloudflare API

    .PARAMETER CFAuthKey
        The auth key of the account associated to the email address entered in the CFAuthEmail parameter.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'admin@example.com' 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtCloudflare {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$CFAuthEmail,
        [Parameter(Mandatory,Position=3)]
        [string]$CFAuthKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = @{'X-Auth-Email'=$CFAuthEmail;'X-Auth-Key'=$CFAuthKey}

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-CFZone $RecordName $CFAuthEmail $CFAuthKey)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    $response = Invoke-RestMethod "$apiRoot/$zoneID/dns_records?type=TXT&name=$RecordName&content=$TxtValue" `
        -Headers $authHeader -ContentType 'application/json' @script:UseBasic

    # remove the txt record if it exists
    if ($response.result.Count -gt 0) {

        $recID = $response.result[0].id
        Write-Verbose "Removing $RecordName with value $TxtValue"
        Invoke-RestMethod "$apiRoot/$zoneID/dns_records/$recID" -Method Delete `
            -ContentType 'application/json' -Headers $authHeader @script:UseBasic | Out-Null

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Cloudflare.

    .DESCRIPTION
        Use Cloudflare V4 api to remove a TXT record to a Cloudflare DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CFAuthEmail
        The email address of the account used to connect to Cloudflare API.

    .PARAMETER CFAuthKey
        The auth key of the account associated to the email address entered in the CFAuthEmail parameter.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'admin@example.com' 'xxxxxxxxxxxx'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtCloudflare {
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

function Find-CFZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$CFAuthEmail,
        [Parameter(Mandatory,Position=2)]
        [string]$CFAuthKey
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:CFRecordZones) { $script:CFRecordZones = @{} }

    # check for the record in the cache
    if ($script:CFRecordZones.ContainsKey($RecordName)) {
        return $script:CFRecordZones.$RecordName
    }

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = @{'X-Auth-Email'=$CFAuthEmail;'X-Auth-Key'=$CFAuthKey}

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {

        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"
        $response = Invoke-RestMethod "$apiRoot/?name=$zoneTest" -Headers $authHeader @script:UseBasic

        # The response object always contains a "result" array even if empty
        if ($response.result.Count -gt 0) {
            Write-Debug ($response | ConvertTo-Json -Depth 5)
            $zoneID = $response.result[0].id
            $script:CFRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}
