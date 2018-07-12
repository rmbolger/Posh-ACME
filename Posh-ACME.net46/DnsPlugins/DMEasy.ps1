function Add-DnsTxtDMEasy {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DMEKey,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$DMESecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$DMESecretInsecure,
        [switch]$DMEUseSandbox,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure secret to a normal string
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DMESecretInsecure = (New-Object PSCredential ("user", $DMESecret)).GetNetworkCredential().Password
    }

    $apiBase = 'https://api.dnsmadeeasy.com/V2.0/dns/managed'
    if ($DMEUseSandbox) {
        $apiBase = 'https://api.sandbox.dnsmadeeasy.com/V2.0/dns/managed'
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneID,$zoneName = Find-DMEZone $RecordName $DMEKey $DMESecretInsecure $apiBase
    if (-not $zoneID) {
        throw "Unable to find DME hosted zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    $recRoot = "$apiBase/$zoneID/records"

    # query the existing record(s)
    try {
        $auth = Get-DMEAuthHeader $DMEKey $DMESecretInsecure
        $response = Invoke-RestMethod "$($recRoot)?recordName=$recShort&type=TXT" `
            -Headers $auth -ContentType 'application/json' @script:UseBasic
    } catch { throw }

    # check if our value is already in there
    if ($response.totalRecords -gt 0) {
        if ("`"$TxtValue`"" -in $response.data.value) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
            return
        }
    }

    # create a new record
    try {
        $auth = Get-DMEAuthHeader $DMEKey $DMESecretInsecure
        $bodyJson = @{name=$recShort;value="`"$TxtValue`"";type='TXT';ttl=10} | ConvertTo-Json -Compress
        Write-Verbose "Creating $RecordName with value $TxtValue"
        Invoke-RestMethod $recRoot -Method Post -Body $bodyJson -Headers $auth `
            -ContentType 'application/json' @script:UseBasic | Out-Null
    } catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to DNS Made Easy.

    .DESCRIPTION
        Add a DNS TXT record to DNS Made Easy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DMEKey
        The DNS Made Easy API key for your account.

    .PARAMETER DMESecret
        The DNS Made Easy API secret key for your account. This SecureString version should only be used on Windows.

    .PARAMETER DMESecretInsecure
        The DNS Made Easy API secret key for your account. This standard String version should be used on non-Windows OSes.

    .PARAMETER DMEUseSandbox
        If specified, all commands will run against the DNS Made Easy sandbox API endpoint. This is generally only used for testing the plugin.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $dmeSecret = Read-Host "DME Secret" -AsSecureString
        PS C:\>Add-DnsTxtDMEasy '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxxxxxx' $dmeSecret

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtDMEasy {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DMEKey,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$DMESecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$DMESecretInsecure,
        [switch]$DMEUseSandbox,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure secret to a normal string
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DMESecretInsecure = (New-Object PSCredential ("user", $DMESecret)).GetNetworkCredential().Password
    }

    $apiBase = 'https://api.dnsmadeeasy.com/V2.0/dns/managed'
    if ($DMEUseSandbox) {
        $apiBase = 'https://api.sandbox.dnsmadeeasy.com/V2.0/dns/managed'
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneID,$zoneName = Find-DMEZone $RecordName $DMEKey $DMESecretInsecure $apiBase
    if (-not $zoneID) {
        throw "Unable to find DME hosted zone for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    $recRoot = "$apiBase/$zoneID/records"

    # query the existing record(s)
    try {
        $auth = Get-DMEAuthHeader $DMEKey $DMESecretInsecure
        $response = Invoke-RestMethod "$($recRoot)?recordName=$recShort&type=TXT" `
            -Headers $auth -ContentType 'application/json' @script:UseBasic
    } catch { throw }

    # check for the value to delete
    if ($response.totalRecords -eq 0) {
        Write-Debug "Record $RecordName doesn't exist. Nothing to do."
        return
    } else {
        if ("`"$TxtValue`"" -notin $response.data.value) {
            Write-Debug "Record $RecordName does not contain $TxtValue. Nothing to do."
            return
        }
        # grab the ID and delete the record
        $recID = ($response.data | Where-Object { $_.value -eq "`"$TxtValue`"" }).id
        try {
            $auth = $auth = Get-DMEAuthHeader $DMEKey $DMESecretInsecure
            Write-Verbose "Deleting record $RecordName with value $TxtValue."
            Invoke-RestMethod "$recRoot/$recID" -Method Delete -Headers $auth `
                -ContentType 'application/json' @script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from DNS Made Easy.

    .DESCRIPTION
        Remove a DNS TXT record from DNS Made Easy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DMEKey
        The DNS Made Easy API key for your account.

    .PARAMETER DMESecret
        The DNS Made Easy API secret key for your account. This SecureString version should only be used on Windows.

    .PARAMETER DMESecretInsecure
        The DNS Made Easy API secret key for your account. This standard String version should be used on non-Windows OSes.

    .PARAMETER DMEUseSandbox
        If specified, all commands will run against the DNS Made Easy sandbox API endpoint. This is generally only used for testing the plugin.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $dmeSecret = Read-Host "DME Secret" -AsSecureString
        PS C:\>Remove-DnsTxtDMEasy '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxxxxxx' $dmeSecret

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtDMEasy {
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

function Get-DMEAuthHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DMEKey,
        [Parameter(Mandatory,Position=1)]
        [string]$DMESecretInsecure
    )

    # We need to initialize an HMACSHA1 instance with the secret key as a byte array.
    # I know there's probably a safer way to do this that doesn't leave the plaintext
    # secret around in memory for as long, but it's beyond me at the moment.
    $secBytes = [Text.Encoding]::UTF8.GetBytes($DMESecretInsecure)
    $hmac = New-Object Security.Cryptography.HMACSHA1($secBytes,$true)

    # We need to hash a timestamp in "HTTP format", aka RFC 1123
    # https://api-docs.dnsmadeeasy.com/#1bf6d47c-61b1-0cf3-4f04-0ed4772561fe
    # https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings#RFC1123
    $reqDate = (Get-DateTimeOffsetNow).ToString('r')
    $dateBytes = [Text.Encoding]::UTF8.GetBytes($reqDate)
    $dateHash = [BitConverter]::ToString($hmac.ComputeHash($dateBytes)).Replace('-','').ToLower()

    # now build the header hashtable
    $header = @{
       'x-dnsme-apiKey'      = $DMEKey;
       'x-dnsme-requestDate' = $reqDate;
       'x-dnsme-hmac'        = $dateHash;
    }

    return $header
}

function Find-DMEZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$DMEKey,
        [Parameter(Mandatory,Position=2)]
        [string]$DMESecretInsecure,
        [Parameter(Mandatory,Position=3)]
        [string]$ApiBase
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DMERecordZones) { $script:DMERecordZones = @{} }

    # check for the record in the cache
    if ($script:DMERecordZones.ContainsKey($RecordName)) {
        return $script:DMERecordZones.$RecordName
    }

    # The response object for managed zones makes it seem like it supports paging with
    # fields like totalPages/page. But the docs don't really make it clear how to
    # request subsequent pages. They also don't say what the max results per page is.
    # So for now, we'll just assume all results get returned in one page. If any large
    # customers find differently, feel free to submit an issue.
    try {
        $auth = Get-DMEAuthHeader $DMEKey $DMESecretInsecure
        $response = Invoke-RestMethod $ApiBase -Headers $auth -ContentType 'application/json' @script:UseBasic
        $zones = @($response.data)
    } catch { throw }

    # Since DME could be hosting both apex and sub-zones, we need to find the closest/deepest
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

        if ($zoneTest -in $zones.name) {
            $zone = $zones | Where-Object { $_.name -eq $zoneTest }
            $script:DMERecordZones.$RecordName = $zone.id,$zone.name
            return $zone.id,$zone.name
        }
    }

    return $null
}
