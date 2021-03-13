function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKHost,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKAccessToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$AKClientSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientSecretInsecure,
        [Parameter(ParameterSetName='EdgeRC',Mandatory)]
        [switch]$AKUseEdgeRC,
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCFile='~\.edgerc',
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCSection='default',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if (-not $script:AKZonesToPoll) { $script:AKZonesToPoll = @() }

    $restParams = Get-AKRestParams @PSBoundParameters

    $zoneName = Find-AKZone $RecordName $restParams
    Write-Verbose "found $zoneName"
    $domainBase = "/config-dns/v2/zones/$zoneName"

    $rec = Invoke-AKRest "$domainBase/names/$RecordName/types/TXT" @restParams

    if ($rec -and "`"$TxtValue`"" -in $rec.rdata) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        if (-not $rec) {
            # build the new record object
            $recBody = @{
                name = $RecordName
                type = 'TXT'
                ttl = 60
                rdata = @($TxtValue)
            } | ConvertTo-Json -Compress

            # add it
            Invoke-AKRest "$domainBase/names/$RecordName/types/TXT" `
                -Method POST -Body $recBody @restParams | Out-Null
        } else {
            # update the rdata with the txt value
            $rec.ttl = $rec.ttl.ToString()
            $rec.rdata = @($TxtValue) + $rec.rdata
            $recBody = $rec | ConvertTo-Json

            # update it
            Invoke-AKRest "$domainBase/names/$RecordName/types/TXT" `
                -Method PUT -Body $recBody @restParams | Out-Null
        }

        # add the zone to the propagation polling list
        if ($zoneName -notin $script:AKZonesToPoll) {
            Write-Debug "Adding $zoneName to polling list"
            $script:AKZonesToPoll += $zoneName
        }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Akamai

    .DESCRIPTION
        Add a DNS TXT record to Akamai

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AKHost
        The Akamai API DNS hostname associated with your credentials.

    .PARAMETER AKAccessToken
        The access_token associated with your credentials.

    .PARAMETER AKClientToken
        The client_token associated with your credentials.

    .PARAMETER AKClientSecret
        The client_secret associated with your credentials. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER AKClientSecretInsecure
        The client_secret associated with your credentials. This standard String version can be used on any OS.

    .PARAMETER AKUseEdgeRC
        If specified, the necessary API tokens will be read from a .edgrc file. Use AKEdgeRCFile and AKEdgeRCSection to specify the details.

    .PARAMETER AKEdgeRCFile
        The path to a .edgerc file with API credentials. Defaults to ~\.edgerc

    .PARAMETER AKEdgeRCSection
        The section that contains the credentials within a .edgerc file. Defaults to "default"

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host -Prompt "Client Secret" -AsSecureString
        PS C:\>$params = @{AKHost='apihost.akamaiapis.net';AKAccessToken='token-value';AKClientToken='token-value';AKClientSecret=$secret}
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' @params

        Adds the specified TXT record with the specified value using explicit API credentials and a secure client secret.

    .EXAMPLE
        $params = @{AKHost='apihost.akamaiapis.net';AKAccessToken='token-value';AKClientToken='token-value';AKClientSecretInsecure='secret-value'}
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' @params

        Adds the specified TXT record with the specified value using explicit API credentials and a plain text client secret.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -AKUseEdgeRC

        Adds the specified TXT record with the specified value using the default .edgerc file and section.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKHost,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKAccessToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$AKClientSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientSecretInsecure,
        [Parameter(ParameterSetName='EdgeRC',Mandatory)]
        [switch]$AKUseEdgeRC,
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCFile='~\.edgerc',
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCSection='default',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $restParams = Get-AKRestParams @PSBoundParameters

    $zoneName = Find-AKZone $RecordName $restParams
    Write-Verbose "found $zoneName"
    $domainBase = "/config-dns/v2/zones/$zoneName"

    $rec = Invoke-AKRest "$domainBase/names/$RecordName/types/TXT" @restParams

    if ($rec -and "`"$TxtValue`"" -in $rec.rdata) {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        if ($rec.rdata.Count -gt 1) {
            # update the rdata with the value removed
            $rec.rdata = @($rec.rdata | Where-Object { $_ -ne "`"$TxtValue`"" })
            $recBody = $rec | ConvertTo-Json

            # update it
            Invoke-AKRest "$domainBase/names/$RecordName/types/TXT" `
                -Method PUT -Body $recBody @restParams | Out-Null
        } else {
            # remove the whole record since this is the only value
            Invoke-AKRest "$domainBase/names/$RecordName/types/TXT" `
                -Method DELETE @restParams | Out-Null
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }




    <#
    .SYNOPSIS
        Remove a DNS TXT record from Akamai

    .DESCRIPTION
        Remove a DNS TXT record from Akamai

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AKHost
        The Akamai API DNS hostname associated with your credentials.

    .PARAMETER AKAccessToken
        The access_token associated with your credentials.

    .PARAMETER AKClientToken
        The client_token associated with your credentials.

    .PARAMETER AKClientSecret
        The client_secret associated with your credentials. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER AKClientSecretInsecure
        The client_secret associated with your credentials. This standard String version can be used on any OS.

    .PARAMETER AKUseEdgeRC
        If specified, the necessary API tokens will be read from a .edgrc file. Use AKEdgeRCFile and AKEdgeRCSection to specify the details.

    .PARAMETER AKEdgeRCFile
        The path to a .edgerc file with API credentials. Defaults to ~\.edgerc

    .PARAMETER AKEdgeRCSection
        The section that contains the credentials within a .edgerc file. Defaults to "default"

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host -Prompt "Client Secret" -AsSecureString
        PS C:\>$params = @{AKHost='apihost.akamaiapis.net';AKAccessToken='token-value';AKClientToken='token-value';AKClientSecret=$secret}
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' @params

        Removes the specified TXT record with the specified value using explicit API credentials and a secure client secret.

    .EXAMPLE
        $params = @{AKHost='apihost.akamaiapis.net';AKAccessToken='token-value';AKClientToken='token-value';AKClientSecretInsecure='secret-value'}
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' @params

        Removes the specified TXT record with the specified value using explicit API credentials and a plain text client secret.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -AKUseEdgeRC

        Removes the specified TXT record with the specified value using the default .edgerc file and section.
    #>
}

function Save-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKHost,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKAccessToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$AKClientSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientSecretInsecure,
        [Parameter(ParameterSetName='EdgeRC',Mandatory)]
        [switch]$AKUseEdgeRC,
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCFile='~\.edgerc',
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCSection='default',
        [int]$AKPollTimeout = 300,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $pollZones = $script:AKZonesToPoll

    if ($pollZones.Count -gt 0) {

        Write-Verbose "Waiting for $($pollZones.Count) zone(s) to become active."

        $restParams = Get-AKRestParams @PSBoundParameters

        $startTime = [DateTimeOffset]::Now
        while ($pollZones.Count -gt 0 -and
            ([DateTimeOffset]::Now - $startTime).TotalSeconds -lt $AKPollTimeout) {

            Start-Sleep 10

            # reverse through the list so the index doesn't change
            # if we remove one
            for ($i = ($pollZones.Count-1); $i -ge 0; $i--) {

                $zone = $pollZones[$i]

                $zoneObject = Invoke-AKRest "/config-dns/v2/zones/$zone" @restParams
                if (-not $zoneObject) {
                    throw "Zone $zone not found while trying to poll activationState."
                }

                if ($zoneObject.activationState -eq 'ACTIVE') {
                    Write-Verbose "$zone is updated"
                    $pollZones = @($pollZones | Where-Object { $_ -ne $zone })
                }
            }
        }
        Write-Debug "Polling stopped after $(([DateTimeOffset]::Now - $startTime).TotalSeconds) seconds"
        if ($pollZones.Count -gt 0) {
            Write-Warning "One or more zones failed to become active before the timeout expired: $(($pollZones -join ', '))"
        }
    }

    $script:AKZonesToPoll = @()


    <#
    .SYNOPSIS
        Block while polling the API for zone status indicating changes have been propagated.

    .DESCRIPTION
        This function will query the activationState of changed zones and wait until each zone has become "ACTIVE" which indicates the changes have finished propagating to the nameservers.

    .PARAMETER AKHost
        The Akamai API DNS hostname associated with your credentials.

    .PARAMETER AKAccessToken
        The access_token associated with your credentials.

    .PARAMETER AKClientToken
        The client_token associated with your credentials.

    .PARAMETER AKClientSecret
        The client_secret associated with your credentials. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER AKClientSecretInsecure
        The client_secret associated with your credentials. This standard String version can be used on any OS.

    .PARAMETER AKUseEdgeRC
        If specified, the necessary API tokens will be read from a .edgrc file. Use AKEdgeRCFile and AKEdgeRCSection to specify the details.

    .PARAMETER AKEdgeRCFile
        The path to a .edgerc file with API credentials. Defaults to ~\.edgerc

    .PARAMETER AKEdgeRCSection
        The section that contains the credentials within a .edgerc file. Defaults to "default"

    .PARAMETER AKPollTimeout
        The number of seconds to wait while polling before giving up. Defaults to 300 (5 minutes).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt -AKUseEdgeRC

        Wait for zone changes to propagate using the default .edgerc file for authentication.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://developer.akamai.com/legacy/introduction/Client_Auth.html
# https://developer.akamai.com/api/cloud_security/edge_dns_zone_management/v2.html
# https://github.com/akamai-contrib/akamaipowershell
# https://github.com/akamai/AkamaiOPEN-edgegrid-powershell

# Despite the client auth protocol docs being in a "legacy" section of the site, there
# does not appear to be any more recent non-legacy auth protocol that works with the
# Akamai APIs as of March 2020.

function Find-AKZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:AKRecordZones) { $script:AKRecordZones = @{} }

    # check for the record in the cache
    if ($script:AKRecordZones.ContainsKey($RecordName)) {
        return $script:AKRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-AKRest "/config-dns/v2/zones?search=$zoneTest&types=primary&showAll=true" @RestParams

            # the search may return multiple partial results, so loop through them
            # looking for an exact match
            foreach ($item in $response.zones) {
                if ($zoneTest -eq $item.zone) {
                    $script:AKRecordZones.$RecordName = $item.zone
                    return $item.zone
                }
            }
        } catch { throw }
    }

    throw "No zone found for $RecordName"
}

function Get-AKRestParams {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKHost,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKAccessToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$AKClientSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AKClientSecretInsecure,
        [Parameter(ParameterSetName='EdgeRC',Mandatory)]
        [switch]$AKUseEdgeRC,
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCFile='~\.edgerc',
        [Parameter(ParameterSetName='EdgeRC')]
        [string]$AKEdgeRCSection='default',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    if ('EdgeRC' -eq $PSCmdlet.ParameterSetName) {
        # get the API values we need from the .edgerc file
        $iniHash = Get-IniContent $AKEdgeRCFile
        if ($AKEdgeRCSection -notin $iniHash.Keys) {
            throw "'$AKEdgeRCSection' section not found in '$AKEdgeRCFile'"
        }

        # return the values from the specified ini section
        return @{
            ApiHost = $iniHash.$AKEdgeRCSection.host
            AccessToken = $iniHash.$AKEdgeRCSection.access_token
            ClientToken = $iniHash.$AKEdgeRCSection.client_token
            ClientSecret = $iniHash.$AKEdgeRCSection.client_secret
        }
    } elseif ('Secure' -eq $PSCmdlet.ParameterSetName) {
        # convert the securestring to a string
        $AKClientSecretInsecure = (New-Object PSCredential "user",$AKClientSecret).GetNetworkCredential().Password
    }

    # return the passed in values
    return @{
        ApiHost = $AKHost
        AccessToken = $AKAccessToken
        ClientToken = $AKClientToken
        ClientSecret = $AKClientSecretInsecure
    }
}

function Invoke-AKRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Path,
        [Parameter(Position=1)]
        [ValidateSet('GET','PUT','POST','DELETE')]
        [string]$Method = 'GET',
        [string]$Body,
        [int]$MaxBody = 131072,
        [string]$AcceptHeader = 'application/json',
        [Parameter(Mandatory)]
        [string]$ApiHost,
        [Parameter(Mandatory)]
        [string]$AccessToken,
        [Parameter(Mandatory)]
        [string]$ClientToken,
        [Parameter(Mandatory)]
        [string]$ClientSecret
    )

    # initialize some stuff we'll need for the signature process
    $uri = [uri]"https://$($ApiHost)$Path"
    $Method = $Method.ToUpper()
    $ts = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHH:mm:sszz00')
    $nonce = (New-Guid).ToString()
    $authString = "EG1-HMAC-SHA256 client_token=$ClientToken;access_token=$AccessToken;timestamp=$ts;nonce=$nonce;"

    # SHA256 hash the body up to the first $MaxBody characters
    $bodyHash = [string]::Empty
    if ($Body -and $Method -eq 'POST') {
        $sha256 = [Security.Cryptography.SHA256]::Create()
        $bodyToHash = if ($Body.Length -le $MaxBody) { $Body } else { $Body.Substring(0,$MaxBody) }
        $bodyBytes = [Text.Encoding]::ASCII.GetBytes($bodyToHash)
        $bodyHash = [Convert]::ToBase64String($sha256.ComputeHash($bodyBytes))
    }

    # Build the signature data
    $sigData = "$Method`thttps`t$($uri.Authority)`t$($uri.PathAndQuery)`t`t$bodyHash`t$authString"

    # Hash the timestamp using the client secret and then use that to
    # hash the signature data to get the signature for the auth header
    $tsHash = Get-HMACSHA256Hash $ClientSecret $ts
    $signature = Get-HMACSHA256Hash $tsHash $sigData

    $headers = @{
        Authorization = "$($authString)signature=$signature"
        Accept = $AcceptHeader
    }

    # Apparently Akamai doesn't support the "Expect: 100 Continue" header
    # and other implementations try to explicitly disable it using
    # [System.Net.ServicePointManager]::Expect100Continue = $false
    # However, none of the environments I tested (PS 5.1, 6, and 7)
    # actually sent that header by default for any HTTP verb.
    # It's plausible it was sent pre-5.1 or pre-.NET 4.7.1. But since
    # we don't support those, we don't have to worry about them.

    # build the call parameters
    $irmParams = @{
        Method = $Method
        Uri = $uri
        Headers = $headers
        ContentType = 'application/json'
        MaximumRedirection = 0
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $irmParams.Body = $Body
    }

    try {
        Invoke-RestMethod @irmParams @script:UseBasic
    } catch {
        # ignore 404 errors and just return $null
        # otherwise, let it through
        if ([Net.HttpStatusCode]::NotFound -eq $_.Exception.Response.StatusCode) {
            return $null
        } else { throw }
    }
}

function Get-HMACSHA256Hash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Key,
        [Parameter(Mandatory,Position=1)]
        [string]$Message
    )

    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::ASCII.GetBytes($Key)
    $msgBytes = [Text.Encoding]::ASCII.GetBytes($Message)
    return [Convert]::ToBase64String($hmac.ComputeHash($msgBytes))
}

function Get-IniContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    # A super basic Regex based INI file parser
    # Sections become keys in a hashtable
    # Key/Value pairs within a section are added to a nested hashtable.
    # Pre/Post whitespace is trimmed from everything
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1].Trim()
            $ini[$section] = @{}
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name.Trim()] = $value.Trim()
        }
    }
    return $ini
}
