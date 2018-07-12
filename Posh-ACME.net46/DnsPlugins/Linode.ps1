function Add-DnsTxtLinode {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$LIToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$LITokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext token if the secure version was used
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $LITokenInsecure = (New-Object PSCredential "user",$LIToken).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.linode.com/v4'
    $restParams = @{
        Headers = @{
            Authorization="Bearer $LITokenInsecure"
            'X-Filter' = '{}'
        }
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneID,$zoneName = Find-LIZone $RecordName $restParams
    Write-Debug "Found zone $zoneID for $zoneName"

    # get all the instances of the record
    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        $restParams.Headers.'X-Filter' = @{name=$recShort;type='TXT'} | ConvertTo-Json -Compress
        $recs = (Invoke-RestMethod "$apiRoot/domains/$zoneID/records" @restParams @script:UseBasic).data
    } catch { throw }
    finally { $restParams.Headers.'X-Filter' = '{}' }

    if (-not $recs -or $TxtValue -notin $recs.target) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $bodyJson = @{name=$recShort;target=$TxtValue;type='TXT';ttl_sec=300} | ConvertTo-Json -Compress
            Invoke-RestMethod "$apiRoot/domains/$zoneID/records" -Method Post -Body $bodyJson `
                @restParams @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Linode.

    .DESCRIPTION
        Add a DNS TXT record to Linode using the v4 API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LIToken
        A Personal Access Token associated with the Linode account that has Read/Write permissions on Domains. This SecureString version should only be used on Windows.

    .PARAMETER LITokenInsecure
        A Personal Access Token associated with the Linode account that has Read/Write permissions on Domains. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Token" -AsSecureString
        PS C:\>Add-DnsTxtLinode '_acme-challenge.site1.example.com' 'asdfqwer12345678' $token

        Adds a TXT record for the specified site with the specified value on Windows.

    .EXAMPLE
        Add-DnsTxtLinode '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value on non-Windows.
    #>
}

function Remove-DnsTxtLinode {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$LIToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$LITokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext token if the secure version was used
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $LITokenInsecure = (New-Object PSCredential "user",$LIToken).GetNetworkCredential().Password
    }

    $apiRoot = 'https://api.linode.com/v4'
    $restParams = @{
        Headers = @{
            Authorization="Bearer $LITokenInsecure"
            'X-Filter' = '{}'
        }
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneID,$zoneName = Find-LIZone $RecordName $restParams
    Write-Debug "Found zone $zoneID for $zoneName"

    # get all the instances of the record
    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        $restParams.Headers.'X-Filter' = @{name=$recShort;type='TXT'} | ConvertTo-Json -Compress
        $recs = (Invoke-RestMethod "$apiRoot/domains/$zoneID/records" @restParams @script:UseBasic).data
    } catch { throw }
    finally { $restParams.Headers.'X-Filter' = '{}' }

    if (-not $recs -or $TxtValue -notin $recs.target) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $recID = ($recs | Where-Object { $_.target -eq $TxtValue }).id
            Invoke-RestMethod "$apiRoot/domains/$zoneID/records/$recID" -Method Delete `
                @restParams @script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Linode.

    .DESCRIPTION
        Add a DNS TXT record to Linode using the v4 API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LIToken
        A Personal Access Token associated with the Linode account that has Read/Write permissions on Domains. This SecureString version should only be used on Windows.

    .PARAMETER LITokenInsecure
        A Personal Access Token associated with the Linode account that has Read/Write permissions on Domains. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Token" -AsSecureString
        PS C:\>Remove-DnsTxtLinode '_acme-challenge.site1.example.com' 'asdfqwer12345678' $token

        Removes a TXT record for the specified site with the specified value on Windows.

    .EXAMPLE
        Remove-DnsTxtLinode '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxxxxxx'

        Removes a TXT record for the specified site with the specified value on non-Windows.
    #>
}

function Save-DnsTxtLinode {
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
# https://developers.linode.com/api/v4

function Find-LIZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:LIRecordZones) { $script:LIRecordZones = @{} }

    # check for the record in the cache
    if ($script:LIRecordZones.ContainsKey($RecordName)) {
        return $script:LIRecordZones.$RecordName
    }

    $apiRoot = 'https://api.linode.com/v4'

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
            $RestParams.Headers.'X-Filter' = "{`"domain`":`"$zoneTest`"}"
            $response = Invoke-RestMethod "$apiRoot/domains" @RestParams @script:UseBasic
            if ($response.data.Count -gt 0) {
                $z = $response.data[0]
                $script:LIRecordZones.$RecordName = $z.id,$z.domain
                return $z.id,$z.domain
            }
        } catch { throw }
        finally {
            $RestParams.Headers.'X-Filter' = '{}'
        }
    }

    return $null
}
