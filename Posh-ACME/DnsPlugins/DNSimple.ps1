function Add-DnsTxtDNSimple {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DSToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$DSTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DSTokenInsecure = (New-Object PSCredential "user",$DSToken).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.dnsimple.com/v2'
    $restParams = @{
        Headers = @{Authorization="Bearer $DSTokenInsecure"}
        ContentType = 'application/json'
    }

    # get the account ID for our token
    try {
        $response = Invoke-RestMethod "$apiRoot/whoami" @restParams @script:UseBasic
        if (!$response.data.account) {
            throw "DNSimple account data not found. Wrong token type?"
        }
        $acctID = $response.data.account.id.ToString()
    } catch { throw }
    Write-Debug "Found account $acctID"

    # get the zone name for our record
    $zoneName = Find-DSZone $RecordName $acctID $restParams
    if ([String]::IsNullOrWhiteSpace($zoneName)) {
        throw "Unable to find zone for $RecordName in account $acctID"
    }
    Write-Debug "Found zone $zoneName"

    # get all the instances of the record
    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        $recs = (Invoke-RestMethod "$apiRoot/$acctID/zones/$zoneName/records?name=$recShort&type=TXT&per_page=100" `
            @restParams @script:UseBasic).data
    } catch { throw }

    if ($recs.Count -eq 0 -or $TxtValue -notin $recs.content) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $bodyJson = @{name=$recShort;type='TXT';content=$TxtValue;ttl=10} | ConvertTo-Json -Compress
            Invoke-RestMethod "$apiRoot/$acctID/zones/$zoneName/records" -Method Post -Body $bodyJson `
                @restParams @script:UseBasic | Out-Null
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
        The Account API token for DNSimple. This SecureString version should only be used on Windows.

    .PARAMETER DSTokenInsecure
        The Account API token for DNSimple. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "DNSimple Token" -AsSecureString
        PS C:\>Add-DnsTxtDNSimple '_acme-challenge.site1.example.com' 'asdfqwer12345678' $token

        Adds a TXT record for the specified site with the specified value on Windows.

    .EXAMPLE
        Add-DnsTxtDNSimple '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value on non-Windows.
    #>
}

function Remove-DnsTxtDNSimple {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DSToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$DSTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DSTokenInsecure = (New-Object PSCredential "user",$DSToken).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.dnsimple.com/v2'
    $restParams = @{
        Headers = @{Authorization="Bearer $DSTokenInsecure"}
        ContentType = 'application/json'
    }

    # get the account ID for our token
    try {
        $response = Invoke-RestMethod "$apiRoot/whoami" @restParams @script:UseBasic
        if (!$response.data.account) {
            throw "DNSimple account data not found. Wrong token type?"
        }
        $acctID = $response.data.account.id.ToString()
    } catch { throw }
    Write-Debug "Found account $acctID"

    # get the zone name for our record
    $zoneName = Find-DSZone $RecordName $acctID $restParams
    if ([String]::IsNullOrWhiteSpace($zoneName)) {
        throw "Unable to find zone for $RecordName in account $acctID"
    }
    Write-Debug "Found zone $zoneName"

    # get all the instances of the record
    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        $recs = (Invoke-RestMethod "$apiRoot/$acctID/zones/$zoneName/records?name=$recShort&type=TXT&per_page=100" `
            @restParams @script:UseBasic).data
    } catch { throw }

    if ($recs.Count -eq 0 -or $TxtValue -notin $recs.content) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $recID = ($recs | Where-Object { $_.content -eq $TxtValue }).id
            Invoke-RestMethod "$apiRoot/$acctID/zones/$zoneName/records/$recID" -Method Delete `
                @restParams @script:UseBasic | Out-Null
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
        The Account API token for DNSimple. This SecureString version should only be used on Windows.

    .PARAMETER DSTokenInsecure
        The Account API token for DNSimple. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "DNSimple Token" -AsSecureString
        PS C:\>Remove-DnsTxtDNSimple '_acme-challenge.site1.example.com' 'asdfqwer12345678' $token

        Removes a TXT record for the specified site with the specified value on Windows.

    .EXAMPLE
        Remove-DnsTxtDNSimple '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxxxxxx'

        Remove a TXT record for the specified site with the specified value on non-Windows.
    #>
}

function Save-DnsTxtDNSimple {
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

function Find-DSZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$AcctID,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DSRecordZones) { $script:DSRecordZones = @{} }

    # check for the record in the cache
    if ($script:DSRecordZones.ContainsKey($RecordName)) {
        return $script:DSRecordZones.$RecordName
    }

    $apiRoot = 'https://api.dnsimple.com/v2'

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            # if the call succeeds, the zone exists, so we don't care about the actualy response
            $null = Invoke-RestMethod "$apiRoot/$AcctID/zones/$zoneTest" @RestParams @script:UseBasic
            $script:DSRecordZones.$RecordName = $zoneTest
            return $zoneTest
        } catch {
            Write-Debug ($_.ToString())
        }
    }

    return $null

}
