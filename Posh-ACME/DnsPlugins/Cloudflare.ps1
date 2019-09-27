function Add-DnsTxtCloudflare {
    [CmdletBinding(DefaultParameterSetName='Email')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Email',Mandatory,Position=2)]
        [string]$CFAuthEmail,
        [Parameter(ParameterSetName='Email',Mandatory,Position=3)]
        [string]$CFAuthKey,
        [Parameter(ParameterSetName='Bearer',Mandatory,Position=2)]
        [securestring]$CFToken,
        [Parameter(ParameterSetName='BearerInsecure',Mandatory,Position=2)]
        [string]$CFTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = Get-CFAuthHeader @PSBoundParameters

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-CFZone $RecordName $authHeader)) {
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
        The Global API Key associated with the email address entered in the CFAuthEmail parameter.

    .PARAMETER CFAuthToken
        The scoped API Token that has been given read/write permissions to the necessary zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFAuthTokenInsecure
        The scoped API Token that has been given read/write permissions to the necessary zones. This standard String version may be used with any OS.

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
        [Parameter(ParameterSetName='Email',Mandatory,Position=2)]
        [string]$CFAuthEmail,
        [Parameter(ParameterSetName='Email',Mandatory,Position=3)]
        [string]$CFAuthKey,
        [Parameter(ParameterSetName='Bearer',Mandatory,Position=2)]
        [securestring]$CFToken,
        [Parameter(ParameterSetName='BearerInsecure',Mandatory,Position=2)]
        [string]$CFTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = Get-CFAuthHeader @PSBoundParameters

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-CFZone $RecordName $authHeader)) {
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
        The Global API Key associated with the email address entered in the CFAuthEmail parameter.

    .PARAMETER CFAuthToken
        The scoped API Token that has been given read/write permissions to the necessary zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFAuthTokenInsecure
        The scoped API Token that has been given read/write permissions to the necessary zones. This standard String version may be used with any OS.

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

# API Docs:
# https://api.cloudflare.com/

function Get-CFAuthHeader {
    [CmdletBinding(DefaultParameterSetName='Email')]
    param(
        [Parameter(ParameterSetName='Email',Mandatory,Position=0)]
        [string]$CFAuthEmail,
        [Parameter(ParameterSetName='Email',Mandatory,Position=1)]
        [string]$CFAuthKey,
        [Parameter(ParameterSetName='Bearer',Mandatory,Position=0)]
        [securestring]$CFToken,
        [Parameter(ParameterSetName='BearerInsecure',Mandatory,Position=0)]
        [string]$CFTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    if ('Email' -eq $PSCmdlet.ParameterSetName) {
        $authHeader = @{
            'X-Auth-Email' = $CFAuthEmail
            'X-Auth-Key'   = $CFAuthKey
        }
    } elseif ('Bearer' -eq $PSCmdlet.ParameterSetName) {
        $CFTokenInsecure = (New-Object PSCredential "user",$CFToken).GetNetworkCredential().Password
        $authHeader = @{
            Authorization = "Bearer $CFTokenInsecure"
        }
    } elseif ('BearerInsecure' -eq $PSCmdlet.ParameterSetName) {
        $authHeader = @{
            Authorization = "Bearer $CFTokenInsecure"
        }
    } else {
        throw "Unable to determine valid auth headers."
    }

    return $authHeader
}

function Find-CFZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$AuthHeader
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:CFRecordZones) { $script:CFRecordZones = @{} }

    # check for the record in the cache
    if ($script:CFRecordZones.ContainsKey($RecordName)) {
        return $script:CFRecordZones.$RecordName
    }

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'

    if (-not $script:CFZoneIDs) {
        $script:CFZoneIDs = @{}

        # Due to a bug in the way Cloudflare implemented their limited scope
        # API tokens, we can't check for domain existence directly because checking
        # for a zone that doesn't exist returns an HTTP 403 which we can't just assume
        # means 'not found'. So instead, we have to retrieve all zones and check
        # locally for existence.
        # https://community.cloudflare.com/t/bug-in-list-zones-endpoint-when-using-api-token/115048
        $page = 0
        do {
            $page++
            try {
                $result = Invoke-RestMethod "$($apiRoot)?page=$page&per_page=50" `
                    -Headers $AuthHeader @script:UseBasic -EA Stop
            } catch { throw }
            $result.result | Where-Object { $_.status -eq 'active' } | ForEach-Object {
                Write-Debug "Found $($_.name) ($($_.id)) on page $page"
                $script:CFZoneIDs[$_.name] = $_.id
            }
        } while ($page -lt $result.result_info.total_pages)
    }

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {

        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        if ($script:CFZoneIDs.ContainsKey($zoneTest)) {
            $zoneID = $script:CFZoneIDs[$zoneTest]
            $script:CFRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}
