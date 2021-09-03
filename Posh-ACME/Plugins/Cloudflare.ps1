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

    if (-not ($zoneID = Find-CFZone $RecordName $authHeader)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    Write-Debug "Checking for existing record"
    try {
        $getParams = @{
            Uri = "$apiRoot/$zoneID/dns_records?type=TXT&name=$RecordName&content=$TxtValue"
            Headers = $authHeader
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($getParams.Uri)"
        $response = Invoke-RestMethod @getParams @script:UseBasic
    } catch { throw }

    # add the new TXT record if necessary
    if ($response.result.Count -eq 0) {

        $bodyJson = @{ type="TXT"; name=$RecordName; content=$TxtValue } | ConvertTo-Json
        Write-Verbose "Adding $RecordName with value $TxtValue"
        try {
            $postParams = @{
                Uri = "$apiRoot/$zoneID/dns_records"
                Method = 'Post'
                Body = $bodyJson
                ContentType = 'application/json'
                Headers = $authHeader
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "POST $($postParams.Uri)"
            Write-Debug "Body`n$($postParams.Body)"
            Invoke-RestMethod @postParams @script:UseBasic | Out-Null
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
        The scoped API Token that has been given read/write permissions to the necessary zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFTokenInsecure
        (DEPRECATED) The scoped API Token that has been given read/write permissions to the necessary zones. This standard String version may be used with any OS.

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

    if (-not ($zoneID = Find-CFZone $RecordName $authHeader)) {
        throw "Unable to find Cloudflare hosted zone for $RecordName"
    }

    # check for an existing record
    Write-Debug "Checking for existing record"
    try {
        $getParams = @{
            Uri = "$apiRoot/$zoneID/dns_records?type=TXT&name=$RecordName&content=$TxtValue"
            Headers = $authHeader
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($getParams.Uri)"
        $response = Invoke-RestMethod @getParams @script:UseBasic
    } catch { throw }

    # remove the txt record if it exists
    if ($response.result.Count -gt 0) {

        $recID = $response.result[0].id
        Write-Verbose "Removing $RecordName with value $TxtValue"
        try {
            $delParams = @{
                Uri = "$apiRoot/$zoneID/dns_records/$recID"
                Method = 'Delete'
                Headers = $authHeader
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "DELETE $($delParams.Uri)"
            Invoke-RestMethod @delParams @script:UseBasic | Out-Null
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
        The scoped API Token that has been given read/write permissions to the necessary zones. This SecureString version can only be used from Windows or any OS with PowerShell Core 6.2+.

    .PARAMETER CFTokenInsecure
        (DEPRECATED) The scoped API Token that has been given read/write permissions to the necessary zones. This standard String version may be used with any OS.

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
        [hashtable]$AuthHeader
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:CFRecordZones) { $script:CFRecordZones = @{} }

    # check for the record in the cache
    if ($script:CFRecordZones.ContainsKey($RecordName)) {
        return $script:CFRecordZones.$RecordName
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"

    $apiRoot = 'https://api.cloudflare.com/client/v4/zones'

    # We need to find the zone ID for the closest/deepest sub-zone that would
    # contain the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {

        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        $response = $null

        try {
            $getParams = @{
                Uri = "$apiRoot/?name=$zoneTest"
                Headers = $AuthHeader
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "GET $($getParams.Uri)"
            $response = Invoke-RestMethod @getParams @script:UseBasic
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
