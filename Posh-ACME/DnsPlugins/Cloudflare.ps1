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
        [Parameter(ParameterSetName='Bearer',Position=3)]
        [securestring]$CFTokenReadAll,
        [Parameter(ParameterSetName='BearerInsecure',Mandatory,Position=2)]
        [string]$CFTokenInsecure,
        [Parameter(ParameterSetName='BearerInsecure',Position=3)]
        [string]$CFTokenReadAllInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = Get-CFAuthHeader @PSBoundParameters
    $authHeaderZoneSearch = Get-CFAuthHeader @PSBoundParameters -ForZoneSearch

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-CFZone $RecordName $authHeaderZoneSearch)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    try {
        $response = Invoke-RestMethod "$apiRoot/$zoneID/dns_records?type=TXT&name=$RecordName&content=$TxtValue" `
            -Headers $authHeader -ContentType 'application/json' @script:UseBasic -EA Stop
    } catch { throw }

    # add the new TXT record if necessary
    if ($response.result.Count -eq 0) {

        $bodyJson = @{ type="TXT"; name=$RecordName; content=$TxtValue } | ConvertTo-Json
        Write-Verbose "Adding $RecordName with value $TxtValue"
        try {
            Invoke-RestMethod "$apiRoot/$zoneID/dns_records" -Method Post -Body $bodyJson `
                -ContentType 'application/json' -Headers $authHeader @script:UseBasic -EA Stop | Out-Null
        } catch { throw }

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

    .PARAMETER CFToken
        The scoped API Token that has been given read/write permissions to the necessary zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFTokenReadAll
        The scoped API Token that has been given read-only permissions to all zones on the account. This is only required if the primary read/write token has been limited to a subset of zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFTokenInsecure
        The scoped API Token that has been given read/write permissions to the necessary zones. This standard String version may be used with any OS.

    .PARAMETER CFTokenReadAllInsecure
        The scoped API Token that has been given read-only permissions to all zones on the account. This is only required if the primary read/write token has been limited to a subset of zones. This standard String version may be used with any OS.

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
    $authHeaderZoneSearch = Get-CFAuthHeader @PSBoundParameters -ForZoneSearch

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-CFZone $RecordName $authHeaderZoneSearch)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    try {
        $response = Invoke-RestMethod "$apiRoot/$zoneID/dns_records?type=TXT&name=$RecordName&content=$TxtValue" `
            -Headers $authHeader -ContentType 'application/json' @script:UseBasic -EA Stop
    } catch { throw }

    # remove the txt record if it exists
    if ($response.result.Count -gt 0) {

        $recID = $response.result[0].id
        Write-Verbose "Removing $RecordName with value $TxtValue"
        try {
            Invoke-RestMethod "$apiRoot/$zoneID/dns_records/$recID" -Method Delete `
                -ContentType 'application/json' -Headers $authHeader @script:UseBasic -EA Stop | Out-Null
        } catch { throw }

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

    .PARAMETER CFToken
        The scoped API Token that has been given read/write permissions to the necessary zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFTokenReadAll
        The scoped API Token that has been given read-only permissions to all zones on the account. This is only required if the primary read/write token has been limited to a subset of zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFTokenInsecure
        The scoped API Token that has been given read/write permissions to the necessary zones. This standard String version may be used with any OS.

    .PARAMETER CFTokenReadAllInsecure
        The scoped API Token that has been given read-only permissions to all zones on the account. This is only required if the primary read/write token has been limited to a subset of zones. This standard String version may be used with any OS.

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
        [Parameter(ParameterSetName='Bearer',Position=1)]
        [securestring]$CFTokenReadAll,
        [Parameter(ParameterSetName='BearerInsecure',Mandatory,Position=0)]
        [string]$CFTokenInsecure,
        [Parameter(ParameterSetName='BearerInsecure',Position=1)]
        [string]$CFTokenReadAllInsecure,
        [switch]$ForZoneSearch,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    if ('Email' -eq $PSCmdlet.ParameterSetName) {
        $authHeader = @{
            'X-Auth-Email' = $CFAuthEmail
            'X-Auth-Key'   = $CFAuthKey
        }
    } elseif ('Bearer' -eq $PSCmdlet.ParameterSetName) {
        if ($ForZoneSearch -and $CFTokenReadAll) {
            $CFTokenInsecure = (New-Object PSCredential "user",$CFTokenReadAll).GetNetworkCredential().Password
        } else {
            $CFTokenInsecure = (New-Object PSCredential "user",$CFToken).GetNetworkCredential().Password
        }
        $authHeader = @{
            Authorization = "Bearer $CFTokenInsecure"
        }
    } elseif ('BearerInsecure' -eq $PSCmdlet.ParameterSetName) {
        if ($ForZoneSearch -and $CFTokenReadAllInsecure) {
            $authHeader = @{
                Authorization = "Bearer $CFTokenReadAllInsecure"
            }
        } else {
            $authHeader = @{
                Authorization = "Bearer $CFTokenInsecure"
            }
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

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {

        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        $response = $null

        try {
            $response = Invoke-RestMethod "$apiRoot/?name=$zoneTest" -Headers $AuthHeader `
                @script:UseBasic -EA Stop
        } catch {
            # When using limited scope API tokens, the API currently throws an
            # HTTP 403 error when a zone we're checking doesn't exist rather than
            # an empty result like it did with the Global Key or something reasonable
            # like a 404 even when you've given read permissions to all zones on the account.
            # Since we have no way of knowing whether the 403 is legitimate or just an indication
            # that the zone doesn't exist, we'll catch it and throw a warning and just
            # re-throw any other errors.
            if (403 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Warning "There was a permissions error checking the existence of $zoneTest. This either indicates the zone doesn't exist or the supplied credentials are invalid. If this is the domain apex and you know the zone exists, check your token permissions. Otherwise, ignore this message."
            } else { throw }
        }

        if ($response -and $response.result.Count -gt 0) {
            $zoneID = $response.result[0].id
            $script:CFRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}
