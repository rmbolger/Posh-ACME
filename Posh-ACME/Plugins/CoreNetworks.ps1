function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$CoreNetworksCred,
        [string]$CoreNetworksApiRoot = 'https://beta.api.core-networks.de',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if (-not $script:CoreNetworksToken) {
        $script:CoreNetworksToken = Get-CoreNetworksAuthToken $CoreNetworksApiRoot $CoreNetworksCred
    }

    ### Authentication at the API via authentication token, which must be sent in the headers of every request.
    $headers = @{
        Authorization="Bearer $($script:CoreNetworksToken)"
    }

    ### Search und find the dns zone of the (sub)domain  (for example: example.com).
    $zoneName = $(Find-CoreNetworksDnsZones $CoreNetworksApiRoot $headers $RecordName)
    Write-Debug $zoneName

    ### Grab the relative portion of the Fully Qualified Domain Name (FQDN)
    $DnsTxtName = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    Write-Debug $DnsTxtName

    # build the add record query
    # API will ignore if the record already exists
    $queryParams = @{
        Uri = "$CoreNetworksApiRoot/dnszones/$zoneName/records/"
        Method = 'POST'
        Body = @{
            name = $DnsTxtName
            ttl  = 60
            type = 'TXT'
            data = "`"$TxtValue`""
        } | ConvertTo-Json
        Headers = $headers
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    ### Send a POST request including bearer authentication.
    try {
        Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
        Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
    }
    catch {
        Write-Debug $_
        throw
    }

    # Add the zone name to a script variable so the Save function can commit
    # all changes at once when it's called.
    if (-not $script:CoreNetworksZones) { $script:CoreNetworksZones = @() }
    $script:CoreNetworksZones += $zoneName

    <#
    .SYNOPSIS
        Add a DNS TXT record to CoreNetworks.

    .DESCRIPTION
        Add a DNS TXT record to CoreNetworks.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CoreNetworksCred
        The API username and password required to authenticate.

    .PARAMETER CoreNetworksApiRoot
        The root URL of the API. Defaults to https://beta.api.core-networks.de

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' -CoreNetworksCred (Get-Credential)

        Adds a TXT record using credentials and ignores certificate validation.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$CoreNetworksCred,
        [string]$CoreNetworksApiRoot = 'https://beta.api.core-networks.de',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if (-not $script:CoreNetworksToken) {
        $script:CoreNetworksToken = Get-CoreNetworksAuthToken $CoreNetworksApiRoot $CoreNetworksCred
    }

    ### Authentication at the API via authentication token, which must be sent in the headers of every request.
    $headers = @{
        Authorization="Bearer $($script:CoreNetworksToken)"
    }

    ### Search und find the dns zone of the (sub)domain  (for example: example.com).
    $zoneName = $(Find-CoreNetworksDnsZones $CoreNetworksApiRoot $headers $RecordName)
    Write-Debug $zoneName

    ### Grab the relative portion of the Fully Qualified Domain Name (FQDN)
    $DnsTxtName = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    Write-Debug $DnsTxtName

    # build the delete record query
    # API will ignore if the record we're deleting doesn't exist
    $queryParams = @{
        Uri = "$CoreNetworksApiRoot/dnszones/$zoneName/records/delete"
        Method = 'POST'
        Body = @{
            name = $DnsTxtName
            data = "`"$TxtValue`""
        } | ConvertTo-Json
        Headers = $headers
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    ### Send a POST request including bearer authentication.
    try {
        Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body)"
        Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
    }
    catch {
        Write-Debug $_
        throw
    }

    # Add the zone name to a script variable so the Save function can commit
    # all changes at once when it's called.
    if (-not $script:CoreNetworksZones) { $script:CoreNetworksZones = @() }
    $script:CoreNetworksZones += $zoneName

    <#
    .SYNOPSIS
        Add a DNS TXT record to CoreNetworks.

    .DESCRIPTION
        Add a DNS TXT record to CoreNetworks.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CoreNetworksCred
        The API username and password required to authenticate.

    .PARAMETER CoreNetworksApiRoot
        The root URL of the API. Defaults to https://beta.api.core-networks.de

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -CoreNetworksCred (Get-Credential)

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]$CoreNetworksCred,
        [string]$CoreNetworksApiRoot = 'https://beta.api.core-networks.de',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    ### Our current backend for the name server is not suitable for the high-frequency processing of DNS records. So that you can make
    ### major changes to DNS zones quickly without having to wait for the name server, changes to the DNS records are not transmitted
    ### to the name servers immediately. Instead, when you are done changing DNS records, you must commit the zone.

    # return early if there's nothing to commit
    if (-not $script:CoreNetworksZones) { return }

    if (-not $script:CoreNetworksToken) {
        $script:CoreNetworksToken = Get-CoreNetworksAuthToken $CoreNetworksApiRoot $CoreNetworksCred
    }

    # get a fresh auth token
    $headers = @{
        Authorization="Bearer $($script:CoreNetworksToken)"
    }

    # commit each unique zone
    $script:CoreNetworksZones | Sort-Object -Unique | ForEach-Object {

        $queryParams = @{
            Uri = "$CoreNetworksApiRoot/dnszones/$_/records/commit"
            Method = 'POST'
            Headers = $headers
            ContentType = 'application/json'
            Verbose = $false
            ErrorAction = 'Stop'
        }

        ### Send a POST request including bearer authentication.
        try {
            Write-Verbose "Committing changes for $_"
            Write-Debug "POST $($queryParams.Uri)"
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        }
        catch {
            Write-Debug $_
            throw
        }

    }

    if ($script:CoreNetworksZones) { Remove-Variable CoreNetworksZones -Scope Script }

    <#
    .SYNOPSIS
        Commit changes made to Core Networks zones

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER CoreNetworksCred
        The API username and password required to authenticate.

    .PARAMETER CoreNetworksApiRoot
        The root URL of the API. Defaults to https://beta.api.core-networks.de

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt -CoreNetworksCred (Get-Credential)

        Commits changes to zones modified by Add-DnsTxt and Remove-DnsTxt.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://beta.api.core-networks.de/doc/


### To get a token, you need an API user account. You can set this up in the API user account management in our web interface.
function Get-CoreNetworksAuthToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$ApiRootUrl,
        [Parameter(Mandatory, Position=1)]
        [pscredential]$Cred
    )

    $passPlain = $Cred.GetNetworkCredential().Password

    # Request a new bearer token using the credentials.
    $queryParams = @{
        Uri = "$ApiRootUrl/auth/token"
        Method = 'POST'
        Body = @{
            login = $Cred.UserName
            password = $passPlain
        } | ConvertTo-Json
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }
    try {
        # sanitize the body so we don't log the plaintext password
        Write-Debug "POST $($queryParams.Uri)`n$($queryParams.Body.Replace($passPlain,'XXXXXXXX'))"

        $data = Invoke-RestMethod @queryParams @script:UseBasic

        return $data.token
    }
    catch {
        Write-Debug $_
        throw
    }
}


### With the following function you get a list of all DNS zones that you currently have.
function Find-CoreNetworksDnsZones {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [System.Object]$ApiRootUrl,
        [Parameter(Mandatory, Position=1)]
        [System.Object]$Headers,
        [Parameter(Mandatory, Position=2)]
        [string]$RecordName
    )

    ### Send a POST request including bearer authentication.
    try {
        $queryParams = @{
            Uri = "$ApiRootUrl/dnszones/"
            Headers = $Headers
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($queryParams.Uri)"
        $data = Invoke-RestMethod @queryParams @script:UseBasic

        foreach ($e in $data.name) {
            if ($RecordName -match $e ) {
                return $e
            }
        }
    }
    catch {
        Write-Debug $_
        throw
    }
}
