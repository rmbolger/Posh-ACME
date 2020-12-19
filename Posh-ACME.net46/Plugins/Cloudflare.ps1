function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Bearer')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Email',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedEmail',Mandatory)]
        [string]$CFAuthEmail,
        [Parameter(ParameterSetName='Email',Mandatory)]
        [securestring]$CFAuthKeySecure,
        [Parameter(ParameterSetName='DeprecatedEmail',Mandatory)]
        [string]$CFAuthKey,
        [Parameter(ParameterSetName='Bearer',Mandatory)]
        [securestring]$CFToken,
        [Parameter(ParameterSetName='DeprecatedBearerInsecure',Mandatory)]
        [string]$CFTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = Get-CFAuthHeader @PSBoundParameters
    $commonParams = @{
        Headers = $authHeader
        Verbose = $false
        Debug = $false
        ErrorAction = 'Stop'
    } + $script:UseBasic

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    if (-not ($zoneID = Find-CFZone $RecordName $apiRoot $commonParams)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    Write-Debug "Checking for existing record"
    try {
        $getParams = $commonParams + @{
            Uri = "$apiRoot/$zoneID/dns_records"
            Body = @{
                type = "TXT"
                name = $RecordName
                content = $TxtValue
            }
        }
        Write-Debug "GET $($getParams.Uri)`n$($getParams.Body | ConvertTo-Json)"
        $response = Invoke-RestMethod @getParams
    } catch { throw }

    # add the new TXT record if necessary
    if ($response.result.Count -eq 0) {

        Write-Verbose "Adding $RecordName with value $TxtValue"
        try {
            $postParams = $commonParams + @{
                Uri = "$apiRoot/$zoneID/dns_records"
                Method = 'Post'
                Body = @{
                    type = "TXT"
                    name = $RecordName
                    content = $TxtValue
                } | ConvertTo-Json
                ContentType = 'application/json'
            }
            Write-Debug "POST $($postParams.Uri)`n$($postParams.Body)"
            Invoke-RestMethod @postParams | Out-Null
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

    .PARAMETER CFAuthKeySecure
        The Global API Key associated with the email address entered in the CFAuthEmail parameter.

    .PARAMETER CFAuthKey
        (DEPRECATED) The Global API Key associated with the email address entered in the CFAuthEmail parameter.

    .PARAMETER CFToken
        The scoped API Token that has been given read/write permissions to the necessary zones.

    .PARAMETER CFTokenInsecure
        (DEPRECATED) The scoped API Token that has been given read/write permissions to the necessary zones.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'API Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -CFToken $token

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Bearer')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Email',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedEmail',Mandatory)]
        [string]$CFAuthEmail,
        [Parameter(ParameterSetName='Email',Mandatory)]
        [securestring]$CFAuthKeySecure,
        [Parameter(ParameterSetName='DeprecatedEmail',Mandatory)]
        [string]$CFAuthKey,
        [Parameter(ParameterSetName='Bearer',Mandatory)]
        [securestring]$CFToken,
        [Parameter(ParameterSetName='DeprecatedBearerInsecure',Mandatory)]
        [string]$CFTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'
    $authHeader = Get-CFAuthHeader @PSBoundParameters
    $commonParams = @{
        Headers = $authHeader
        Verbose = $false
        Debug = $false
        ErrorAction = 'Stop'
    } + $script:UseBasic

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    if (-not ($zoneID = Find-CFZone $RecordName $apiRoot $commonParams)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    Write-Debug "Checking for existing record"
    try {
        $getParams = $commonParams + @{
            Uri = "$apiRoot/$zoneID/dns_records"
            Body = @{
                type = "TXT"
                name = $RecordName
                content = $TxtValue
            }
        }
        Write-Debug "GET $($getParams.Uri)`n$($getParams.Body | ConvertTo-Json)"
        $response = Invoke-RestMethod @getParams
    } catch { throw }

    # remove the txt record if it exists
    if ($response.result.Count -gt 0) {

        $recID = $response.result[0].id
        Write-Verbose "Removing $RecordName with value $TxtValue"
        try {
            $delParams = $commonParams + @{
                Uri = "$apiRoot/$zoneID/dns_records/$recID"
                Method = 'Delete'
            }
            Write-Debug "DELETE $($delParams.Uri)"
            Invoke-RestMethod @delParams | Out-Null
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
        The email address of the account used to connect to Cloudflare API

    .PARAMETER CFAuthKeySecure
        The Global API Key associated with the email address entered in the CFAuthEmail parameter.

    .PARAMETER CFAuthKey
        (DEPRECATED) The Global API Key associated with the email address entered in the CFAuthEmail parameter.

    .PARAMETER CFToken
        The scoped API Token that has been given read/write permissions to the necessary zones.

    .PARAMETER CFTokenInsecure
        (DEPRECATED) The scoped API Token that has been given read/write permissions to the necessary zones.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'API Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -CFToken $token

        Removes a TXT record for the specified site with the specified value.
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
# https://api.cloudflare.com/

function Get-CFAuthHeader {
    [CmdletBinding(DefaultParameterSetName='Bearer')]
    param(
        [Parameter(ParameterSetName='Email',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedEmail',Mandatory)]
        [string]$CFAuthEmail,
        [Parameter(ParameterSetName='Email',Mandatory)]
        [securestring]$CFAuthKeySecure,
        [Parameter(ParameterSetName='DeprecatedEmail',Mandatory)]
        [string]$CFAuthKey,
        [Parameter(ParameterSetName='Bearer',Mandatory)]
        [securestring]$CFToken,
        [Parameter(ParameterSetName='DeprecatedBearerInsecure',Mandatory)]
        [string]$CFTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    if ('Email' -eq $PSCmdlet.ParameterSetName) {
        $CFAuthKey = [pscredential]::new('a',$CFAuthKeySecure).GetNetworkCredential().Password
        return @{
            'X-Auth-Email' = $CFAuthEmail
            'X-Auth-Key'   = $CFAuthKey
        }
    } elseif ('DeprecatedEmail' -eq $PSCmdlet.ParameterSetName) {
        return @{
            'X-Auth-Email' = $CFAuthEmail
            'X-Auth-Key'   = $CFAuthKey
        }
    } elseif ('Bearer' -eq $PSCmdlet.ParameterSetName) {

        $CFTokenInsecure = [pscredential]::new('a',$CFToken).GetNetworkCredential().Password
        return @{ Authorization = "Bearer $CFTokenInsecure" }

    } elseif ('DeprecatedBearerInsecure' -eq $PSCmdlet.ParameterSetName) {

        return @{ Authorization = "Bearer $CFTokenInsecure" }

    } else {
        throw "Unable to determine valid auth headers."
    }
}

function Find-CFZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ApiRoot,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$CommonParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:CFRecordZones) { $script:CFRecordZones = @{} }

    # check for the record in the cache
    if ($script:CFRecordZones.ContainsKey($RecordName)) {
        return $script:CFRecordZones.$RecordName
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {

        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        $response = $null

        try {
            $getParams = $commonParams + @{
                Uri = $ApiRoot
                Body = @{name = $zoneTest}
            }
            Write-Debug "GET $($getParams.Uri)`n$($getParams.Body | ConvertTo-Json)"
            $response = Invoke-RestMethod @getParams
        } catch {
            # UPDATE: As of Feb 2021, Cloudflare seems to have fixed the bug where
            # querying a zone that doesn't exist with a limited scope API token
            # throws an HTTP 403 error. It now works the same way it does with
            # the global key and just returns an empty result set. 403 errors now
            # only seem to be thrown on legitimate permission problems.
            if (403 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Warning "There was a permissions error checking the existence of $zoneTest. This indicates the supplied credentials are invalid. Please double check your token permissions."
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
