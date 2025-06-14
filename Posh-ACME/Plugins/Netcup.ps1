function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [int]$NetcupCustNumber,
        [Parameter(Mandatory)]
        [pscredential]$NetcupAPICredential,
        [string]$NetcupEndpoint='https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $script:NetcupEndpoint = $NetcupEndpoint

    $zone,$rec = Get-NetcupTxtRecord @PSBoundParameters

    if ($rec) {
        Write-Verbose "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    if (-not $recShort) { $recShort = '@' }

    $queryParams = @{
        NetcupCustNumber = $NetcupCustNumber
        NetcupAPICredential = $NetcupAPICredential
        Request = @{
            action = 'updateDnsRecords'
            param = @{
                domainname = $zone
                dnsrecordset = @{
                    dnsrecords = @(@{
                        hostname = $recShort
                        type = 'TXT'
                        destination = $TxtValue
                        deleterecord = $false
                    })
                }
            }
        }
    }
    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
    $resp = Invoke-NetcupRequest @queryParams
    if ($resp -and $resp.dnsrecords) {
        $rec = $resp.dnsrecords | Where-Object {
            $_.hostname -eq $recShort -and $_.destination -eq $TxtValue
        }
        Write-Debug "New record ID $($rec.id)"
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Netcup

    .DESCRIPTION
        Description for Netcup

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NetcupCustNumber
        The customer number of your Netcup account. This is also the username you use to login to the portal with.

    .PARAMETER NetcupAPICredential
        The Netcup API Key and Password you have configured in the portal as a PSCredential object. The Key should be the username.

    .PARAMETER NetcupEndpoint
        The URI of the Netcup REST API endpoint. The default should work unless Netcup changes it.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -NetcupCustNumber 123456 -NetcupAPICredential (Get-Credential)

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
        [int]$NetcupCustNumber,
        [Parameter(Mandatory)]
        [pscredential]$NetcupAPICredential,
        [string]$NetcupEndpoint='https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $script:NetcupEndpoint = $NetcupEndpoint

    $zone,$rec = Get-NetcupTxtRecord @PSBoundParameters

    if (-not $rec) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }

    $queryParams = @{
        NetcupCustNumber = $NetcupCustNumber
        NetcupAPICredential = $NetcupAPICredential
        Request = @{
            action = 'updateDnsRecords'
            param = @{
                domainname = $zone
                dnsrecordset = @{
                    dnsrecords = @(@{
                        id = $rec.id
                        hostname = $rec.hostname
                        type = 'TXT'
                        destination = $TxtValue
                        deleterecord = $true
                    })
                }
            }
        }
    }
    Write-Verbose "Deleting TXT record $($rec.id) for $RecordName with value $TxtValue"
    $resp = Invoke-NetcupRequest @queryParams
    if ($resp -and $resp.dnsrecords) {
        $rec = $resp.dnsrecords | Where-Object {
            $_.hostname -eq $recShort -and $_.destination -eq $TxtValue
        }
        if (-not $rec) {
            Write-Debug "Deleted successfully"
        }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Netcup

    .DESCRIPTION
        Description for Netcup

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NetcupCustNumber
        The customer number of your Netcup account. This is also the username you use to login to the portal with.

    .PARAMETER NetcupAPICredential
        The Netcup API Key and Password you have configured in the portal as a PSCredential object. The Key should be the username.

    .PARAMETER NetcupEndpoint
        The URI of the Netcup REST API endpoint. The default should work unless Netcup changes it.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -NetcupCustNumber 123456 -NetcupAPICredential (Get-Credential)

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

# https://helpcenter.netcup.com/en/wiki/general/our-api

function New-NetcupSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [int]$NetcupCustNumber,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$NetcupAPICredential
    )

    $queryParams = @{
        Uri = $script:NetcupEndpoint
        Method = 'POST'
        Body = @{
            action = 'login'
            param = @{
                customernumber = $NetcupCustNumber
                apikey = $NetcupAPICredential.UserName
                apipassword = $NetcupAPICredential.GetNetworkCredential().Password
            }
        } | ConvertTo-Json -Compress
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    Write-Debug "Logging in as customer $NetcupCustNumber."
    $resp = Invoke-RestMethod @queryParams @script:UseBasic
    if ($resp.status -eq 'success') {
        $script:NetcupSession = @{
            customernumber = $NetcupCustNumber
            apikey = $NetcupAPICredential.UserName
            apisessionid = $resp.responsedata.apisessionid
        }
    } else {
        try { throw "Netcup error $($resp.statuscode): $($resp.longmessage)" }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }
}

function Invoke-NetcupRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [int]$NetcupCustNumber,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$NetcupAPICredential,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$Request
    )

    # Netcup seems to be having some sort of API issue that times out session tokens
    # very quickly. Their docs claim the session is supposed to last 15 minutes, but
    # after what feels like 15 seconds, the API starts returning errors such as
    #     "The session id is not in a valid format."
    # So we're going to implement a retry mechanism to get a new session if it this
    # function gets that specific error code.

    if (-not $script:NetcupEndpoint) {
        $script:NetcupEndpoint = 'https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON'
    }
    if (-not $script:NetcupSession) {
        New-NetcupSession $NetcupCustNumber $NetcupAPICredential
    }

    $tries = 0
    while ($tries -lt 2) {
        $tries++

        # inject the current session into the request
        $req = @{
            action = $Request.action
            param = ($Request.param + $script:NetcupSession)
        }
        $queryParams = @{
            Uri = $script:NetcupEndpoint
            Method = 'POST'
            Body = $req | ConvertTo-Json -Compress -Depth 10
            ContentType = 'application/json'
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "POST $($queryParams.Uri)`n$($Request|ConvertTo-Json -Depth 10)"

        $resp = Invoke-RestMethod @queryParams @script:UseBasic
        if ($resp.status -eq 'success') {
            return $resp.responsedata
        } else {
            if ($resp.statuscode -eq 4001) {
                Write-Debug "Netcup error $($resp.statuscode): $($resp.longmessage)"
                New-NetcupSession $NetcupCustNumber $NetcupAPICredential
                continue
            } elseif ($resp.statuscode -in 5029,4013) {
                Write-Debug "Netcup error $($resp.statuscode): $($resp.longmessage)"
                # 5029 = "Domain not found" for infoDnsRecords
                # 4013 = "Invalid domain name" for infoDnsRecords
                return $null
            } else {
                try { throw "Netcup error $($resp.statuscode): $($resp.longmessage)" }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
    }

    # We should only get here if we ran out of retries getting a working session ID
    # which means logging in was successful but the API is not accepting the session
    # ID value it gave us.
    try { throw "Unable to obtain a valid Netcup apisessionid." }
    catch { $PSCmdlet.ThrowTerminatingError($_) }
}

function Get-NetcupTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [int]$NetcupCustNumber,
        [Parameter(Mandatory)]
        [pscredential]$NetcupAPICredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams2
    )

    $zone = $null
    $allrecs = $null

    # setup a module variable to cache the record to zone mapping
    if (-not $script:NetcupRecordZones) { $script:NetcupRecordZones = @{} }

    # check for the record in the cache
    if ($script:NetcupRecordZones.ContainsKey($RecordName)) {
        $zone = $script:NetcupRecordZones.$RecordName
    }

    if (-not $zone) {
        # For whatever reason, the 'listallDomains' action is only available for resellers.
        # So we're just going to try 'infoDnsRecords' for various portions of the
        # RecordName until we find them or run out of options.
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {
            $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
            Write-Debug "Checking $zoneTest"

            $queryParams = @{
                NetcupCustNumber = $NetcupCustNumber
                NetcupAPICredential = $NetcupAPICredential
                Request = @{
                    action = 'infoDnsRecords'
                    param = @{ domainname = $zoneTest }
                }
            }
            try {
                # a non-null result means records were returned and we found
                # the matching zone
                if ($resp = Invoke-NetcupRequest @queryParams) {
                    Write-Debug "Found matching zone $zoneTest"
                    $zone = $zoneTest
                    $script:NetcupRecordZones.$RecordName = $zoneTest
                    $allrecs = $resp.dnsrecords
                    Write-Debug "Found $($allrecs.Count) existing records"
                }
            } catch { throw }
        }
    }

    if (-not $allrecs) {
        # We already have the zone from a previous call, so re-grab the current
        # record list.
        $queryParams = @{
            NetcupCustNumber = $NetcupCustNumber
            NetcupAPICredential = $NetcupAPICredential
            Request = @{
                action = 'infoDnsRecords'
                param = @{ domainname = $zone }
            }
        }
        $resp = Invoke-NetcupRequest @queryParams
        $allrecs = $resp.dnsrecords
        Write-Debug "Found $($allrecs.Count) existing records"
    }

    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zone.TrimEnd('.')))$",''
    if (-not $recShort) { $recShort = '@' }

    $rec = $allrecs | Where-Object {
        $_.type -eq 'TXT' -and
        $_.hostname -eq $recShort -and
        $_.destination -eq $TxtValue
    }
    return $zone,$rec
}
