function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$ISPConfigCredential,
        [Parameter(Mandatory)]
        [string]$ISPConfigEndpoint,
        [switch]$ISPConfigIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $restSplat = @{
        Credential = $ISPConfigCredential
        Endpoint = $ISPConfigEndpoint
    }

    try {
        # ignore cert validation for the duration of the call
        if ($ISPConfigIgnoreCert) { Set-ISPConfigCertIgnoreOn }

        # find the zone/server details
        $zoneID,$zoneName,$serverID = Find-ISPConfigZone $RecordName @restSplat
        if ($zoneID) {
            Write-Debug "id: $zoneID, name: $zoneName, server ID: $serverID"
        } else {
            throw "Zone not found for record $RecordName"
        }

        # separate the portion of the name that doesn't contain the zone name
        $recShort = ("$RecordName." -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        if ($recShort -eq '') { $recShort = "$RecordName." }

        # check for an existing record
        $rec = Get-ISPConfigZoneTxtRecord $recShort $TxtValue $zoneID @restSplat

        if ($rec) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        } else {
            try {
                $queryParams = @{
                    Function = 'dns_txt_add'
                    BodyParams = @{
                        client_id = $null
                        update_serial = $true
                        params = @{
                            server_id = $serverID
                            zone = $zoneID
                            name = $recShort
                            type = 'TXT'
                            data = $TxtValue
                            active = 'Y'
                            ttl = 60
                            stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                        }

                    }
                }
                Write-Verbose "Adding record '$recShort' with value '$TxtValue'"
                Invoke-ISPConfigRest @queryParams @restSplat | Out-Null
            }
            catch { throw }
        }

    } finally {
        # return cert validation back to normal
        if ($ISPConfigIgnoreCert) { Set-ISPConfigCertIgnoreOff }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to ISPConfig

    .DESCRIPTION
        Add a DNS TXT record to ISPConfig

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ISPConfigCredential
        Username and password the has access to create the necessary TXT records in ISPConfig.

    .PARAMETER ISPConfigEndpoint
        URL for the ISPConfig instance's remote API (e.g. https://example.com/remote/json.php)

    .PARAMETER ISPConfigIgnoreCert
        Use this switch to prevent certificate errors when your ISPConfig server is using a self-signed or other untrusted SSL certificate.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -ISPConfigCredential (Get-Credential) -ISPConfigEndpoint https://example.com/remote/json.php

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$ISPConfigCredential,
        [Parameter(Mandatory)]
        [string]$ISPConfigEndpoint,
        [switch]$ISPConfigIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $restSplat = @{
        Credential = $ISPConfigCredential
        Endpoint = $ISPConfigEndpoint
    }

    try {
        # ignore cert validation for the duration of the call
        if ($ISPConfigIgnoreCert) { Set-ISPConfigCertIgnoreOn }

        # find the zone/server details
        $zoneID,$zoneName,$serverID = Find-ISPConfigZone $RecordName @restSplat
        if ($zoneID) {
            Write-Debug "id: $zoneID, name: $zoneName, server ID: $serverID"
        } else {
            throw "Zone not found for record $RecordName"
        }

        # separate the portion of the name that doesn't contain the zone name
        $recShort = ("$RecordName." -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        if ($recShort -eq '') { $recShort = "$RecordName." }

        # check for an existing record
        $rec = Get-ISPConfigZoneTxtRecord $recShort $TxtValue $zoneID @restSplat

        if ($rec) {
            try {
                $queryParams = @{
                    Function = 'dns_txt_delete'
                    BodyParams = @{
                        primary_id = $rec.id
                        update_serial = $true
                    }
                }
                Write-Verbose "Deleting record id $($rec.id), '$($rec.name)' with value '$($rec.data)'"
                Invoke-ISPConfigRest @queryParams @restSplat | Out-Null
            }
            catch { throw }
        } else {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        }

    } finally {
        # return cert validation back to normal
        if ($ISPConfigIgnoreCert) { Set-ISPConfigCertIgnoreOff }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from ISPConfig.

    .DESCRIPTION
        Remove a DNS TXT record from ISPConfig.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ISPConfigCredential
        Username and password the has access to create the necessary TXT records in ISPConfig.

    .PARAMETER ISPConfigEndpoint
        URL for the ISPConfig instance's remote API (e.g. https://example.com/remote/json.php)

    .PARAMETER ISPConfigIgnoreCert
        Use this switch to prevent certificate errors when your ISPConfig server is using a self-signed or other untrusted SSL certificate.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -ISPConfigCredential (Get-Credential) -ISPConfigEndpoint https://example.com/remote/json.php

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

# https://git.ispconfig.org/ispconfig/ispconfig3/-/tree/develop/remoting_client/API-docs
# https://github.com/m42e/certbot-dns-ispconfig/blob/master/certbot_dns_ispconfig/dns_ispconfig.py

function Invoke-ISPConfigRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [pscredential]$Credential,
        [Parameter(Mandatory,Position=1)]
        [string]$Endpoint,
        [Parameter(Mandatory)]
        [string]$Function,
        [hashtable]$BodyParams
    )

    if ($Function -eq 'login') {
        # build login params
        $uri = "{0}?login" -f $Endpoint
        $pass = $ISPConfigCredential.GetNetworkCredential().Password
        $body = @{
            username = $ISPConfigCredential.UserName
            password = $pass
        } | ConvertTo-Json
        $bodySanitized = $body.Replace($pass,'XXXXXXXX')
    }
    else {
        if (-not $script:ISPConfigSessionID) {
            # recurse and login first
            try {
                Write-Debug "recursing to login"
                $script:ISPConfigSessionID = Invoke-ISPConfigRest $Credential $Endpoint -Function 'login'
            } catch { Write-Debug "login recurse failed"; throw }
            if (-not $script:ISPConfigSessionID) {
                throw "no session ID found after logging in"
            }
        }

        # build function params with the session ID
        $uri = "{0}?{1}" -f $Endpoint,$Function
        $BodyParams.session_id = $script:ISPConfigSessionID
        $body = $BodyParams | ConvertTo-Json -Depth 5
        $bodySanitized = $body
    }

    # build rest splat
    $restParams = @{
        Uri = $uri
        Method = 'POST'
        Body = $body
        Verbose = $false
    }
    try {
        Write-Debug "POST $uri`n$bodySanitized"
        $response = Invoke-RestMethod @restParams @script:UseBasic
    } catch { throw }

    if ($response.code -eq 'ok') {
        return $response.response
    }
    elseif ($response.code -eq 'remote_fault') {
        # re-try if session expired "The Session is expired or does not exist."
        if ($response.message -like '*expired*') {
            Write-Debug "session expired, retrying with fresh login"
            $script:ISPConfigSessionID = $null
            try {
                return Invoke-ISPConfigRest @PSBoundParameters
            } catch { throw }
        } else {
            throw "ISPConfig Error: $($response.message)"
        }
    }
    else {
        throw "Unexpected error with ISPConfig:`n$($response | ConvertTo-Json)"
    }
}

function Find-ISPConfigZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$Credential,
        [Parameter(Mandatory,Position=2)]
        [string]$Endpoint
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:ISPConfigRecordZones) { $script:ISPConfigRecordZones = @{} }

    # check for the record in the cache
    if ($script:ISPConfigRecordZones.ContainsKey($RecordName)) {
        return $script:ISPConfigRecordZones.$RecordName
    }

    # Find the closest/deepest sub-zone that would hold the record.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        try {
            $queryParams = @{
                Function = 'dns_zone_get'
                BodyParams = @{
                    primary_id = @{
                        origin = "$zoneTest."
                    }
                }
                Credential = $Credential
                Endpoint = $Endpoint
            }

            $response = Invoke-ISPConfigRest @queryParams
        } catch { throw }

        if ($response) {
            $script:ISPConfigRecordZones.$RecordName = $response.id,$response.origin,$response.server_id
            return $response.id,$response.origin,$response.server_id
        }
    }

    return $null
}

function Get-ISPConfigZoneTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordShort,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZoneID,
        [Parameter(Mandatory,Position=3)]
        [pscredential]$Credential,
        [Parameter(Mandatory,Position=4)]
        [string]$Endpoint
    )

    try {
        $queryParams = @{
            Function = 'dns_rr_get_all_by_zone'
            BodyParams = @{
                zone_id = $ZoneID
            }
            Credential = $Credential
            Endpoint = $Endpoint
        }

        Invoke-ISPConfigRest @queryParams | Where-Object {
            $_.name -eq $RecordShort -and
            $_.type -eq 'TXT' -and
            $_.data -eq $TxtValue
        } | Select-Object id,name,type,'data'
    }
    catch { throw }
}

function Set-ISPConfigCertIgnoreOn {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if (-not $script:UseBasic.SkipCertificateCheck) {
            # temporarily set skip to true
            $script:UseBasic.SkipCertificateCheck = $true
            # remember that we did
            $script:ISPConfigUnsetIgnoreAfter = $true
        }

    } else {
        # Desktop edition
        [CertValidation]::Ignore()
    }
}

function Set-ISPConfigCertIgnoreOff {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if ($script:ISPConfigUnsetIgnoreAfter) {
            $script:UseBasic.SkipCertificateCheck = $false
            Remove-Variable ISPConfigUnsetIgnoreAfter -Scope Script
        }

    } else {
        # Desktop edition
        [CertValidation]::Restore()
    }
}
