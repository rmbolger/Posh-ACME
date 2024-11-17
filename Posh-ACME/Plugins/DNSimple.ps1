function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DSToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$DSTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DSTokenInsecure = [pscredential]::new('a',$DSToken).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.dnsimple.com/v2'
    $commonParams = @{
        Headers = @{Authorization="Bearer $DSTokenInsecure"}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
    }

    # get the zone name for our record
    $zoneName,$acctID = Find-DSZone $RecordName $commonParams
    if (-not $zoneName) {
        throw "Unable to find zone for $RecordName"
    }
    Write-Debug "Found zone $zoneName in account $acctID"

    # get all the instances of the record
    try {
        $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
        $uri = "$apiRoot/$acctID/zones/$zoneName/records?name=$recShort&type=TXT&per_page=100"
        Write-Debug "GET $uri"
        $resp = Invoke-RestMethod $uri @commonParams @script:UseBasic
        Write-Debug "Response:`n$($resp | ConvertTo-Json -Depth 10)"
        # We're ignoring potential pagination here because there really shouldn't be more than 100
        # TXT records with the same FQDN in the zone.
    } catch { throw }

    $rec = $resp.data | Where-Object { $_.content -eq "`"$TxtValue`"" }

    if (-not $rec) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $uri = "$apiRoot/$acctID/zones/$zoneName/records"
            $bodyJson = @{name=$recShort;type='TXT';content=$TxtValue;ttl=10} | ConvertTo-Json -Compress
            Write-Debug "POST $uri`n$bodyJson"
            $null = Invoke-RestMethod $uri -Method Post -Body $bodyJson @commonParams @script:UseBasic
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to DNSimple.

    .DESCRIPTION
        Add a DNS TXT record to DNSimple.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DSToken
        The Account API token for DNSimple.

    .PARAMETER DSTokenInsecure
        (DEPRECATED) The Account API token for DNSimple.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "DNSimple Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds a TXT record for the specified site with the specified value on Windows.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DSToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$DSTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DSTokenInsecure = [pscredential]::new('a',$DSToken).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.dnsimple.com/v2'
    $commonParams = @{
        Headers = @{Authorization="Bearer $DSTokenInsecure"}
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose = $false
    }

    # get the zone name for our record
    $zoneName,$acctID = Find-DSZone $RecordName $commonParams
    if (-not $zoneName) {
        throw "Unable to find zone for $RecordName"
    }
    Write-Debug "Found zone $zoneName in account $acctID"

    # get all the instances of the record
    try {
        $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
        $uri = "$apiRoot/$acctID/zones/$zoneName/records?name=$recShort&type=TXT&per_page=100"
        Write-Debug "GET $uri"
        $resp = Invoke-RestMethod $uri @commonParams @script:UseBasic
        Write-Debug "Response:`n$($resp | ConvertTo-Json -Depth 10)"
        # We're ignoring potential pagination here because there really shouldn't be more than 100
        # TXT records with the same FQDN in the zone.
    } catch { throw }

    $rec = $resp.data | Where-Object { $_.content -eq "`"$TxtValue`"" }

    if (-not $rec) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $uri = "$apiRoot/$acctID/zones/$zoneName/records/$($rec.id)"
            Write-Debug "DELETE $uri"
            $null = Invoke-RestMethod $uri -Method Delete @commonParams @script:UseBasic
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from DNSimple.

    .DESCRIPTION
        Remove a DNS TXT record from DNSimple.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DSToken
        The Account API token for DNSimple.

    .PARAMETER DSTokenInsecure
        (DEPRECATED) The Account API token for DNSimple.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "DNSimple Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes a TXT record for the specified site with the specified value on Windows.
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

# API Docs
# https://developer.dnsimple.com/v2/
# https://developer.dnsimple.com/sandbox/

function Find-DSZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CommonRestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DSRecordZones) { $script:DSRecordZones = @{} }

    # check for the record in the cache
    if ($script:DSRecordZones.ContainsKey($RecordName)) {
        return $script:DSRecordZones.$RecordName
    }

    $apiRoot = 'https://api.dnsimple.com/v2'

    # DNSimple API Tokens can either be associated with a specific account or a user that has
    # access to multiple accounts. Zones data must be queried using a specific account ID.
    # So we need to use the /accounts endpoint to find out what accounts our token has access
    # to and then query each one for the zone we're looking for.

    Write-Debug "Checking accounts for a matching zone"
    try {
        $uri = "$apiRoot/accounts"
        Write-Debug "GET $uri"
        $resp = Invoke-RestMethod $uri @CommonRestParams @script:UseBasic
        Write-Debug "Response:`n$($resp | ConvertTo-Json -Depth 10)"
        $accounts = @($resp.data)
    } catch { throw }

    # try successively more generic portions of the RecordName for a zone match
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'

        # check each account our token has access to
        foreach ($acct in $accounts) {

            try {
                $uri = '{0}/{1}/zones/{2}' -f $apiRoot,$acct.id,$zoneTest
                Write-Debug "GET $uri"
                $null = Invoke-RestMethod $uri @CommonRestParams @script:UseBasic
                # if we made it here, we found the zone
                $script:DSRecordZones.$RecordName = $zoneTest,$acct.id
                return @($zoneTest,$acct.id)
            } catch {
                # re-throw anything other than a 404
                if ($_.Exception.Response.StatusCode -ne 404) {
                    throw
                }
            }
        }
    }

    return $null

}
