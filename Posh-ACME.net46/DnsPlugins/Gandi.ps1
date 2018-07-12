function Add-DnsTxtGandi {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$GandiToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$GandiTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $GandiTokenInsecure = (New-Object PSCredential "user",$GandiToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            'X-Api-Key' = $GandiTokenInsecure
            Accept = 'application/json'
        }
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneName = Find-GandiZone $RecordName $restParams
    Write-Debug "Found zone $zoneName"

    # find the matching TXT record if it exists
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    $recUrl = "https://dns.api.gandi.net/api/v5/domains/$zoneName/records/$recShort/TXT"
    try {
        $rec = Invoke-RestMethod $recUrl @restParams @script:UseBasic -EA Stop
    } catch {}

    if ($rec -and "`"$TxtValue`"" -in $rec.rrset_values) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        if (-not $rec) {
            # add new record
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $body = @{rrset_values=@("`"$TxtValue`"")}
            Write-Debug "Sending body:`n$(($body | ConvertTo-Json))"
            $bodyJson = $body | ConvertTo-Json -Compress
            try {
                Invoke-RestMethod $recUrl -Method Post -Body $bodyJson `
                    @restParams @script:UseBasic -EA Stop | Out-Null
            } catch { throw }
        } else {
            # update the existing record
            Write-Verbose "Updating a TXT record for $RecordName with value $TxtValue"
            $body = @{rrset_values=(@($rec.rrset_values) + @("`"$TxtValue`""))}
            Write-Debug "Sending body:`n$(($body | ConvertTo-Json))"
            $bodyJson = $body | ConvertTo-Json -Compress
            try {
                Invoke-RestMethod $recUrl -Method Put -Body $bodyJson `
                    @restParams @script:UseBasic -EA Stop | Out-Null
            } catch { throw }
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Gandi.

    .DESCRIPTION
        Add a DNS TXT record to Gandi.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GandiToken
        The API token for your Gandi account. This SecureString version should only be used on Windows.

    .PARAMETER GandiTokenInsecure
        The API token for your Gandi account. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Gandi Token" -AsSecureString
        PS C:\>Add-DnsTxtGandi '_acme-challenge.site1.example.com' 'asdfqwer12345678' $token

        Adds a TXT record using a securestring object for GandiToken. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxtGandi '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxx'

        Adds a TXT record using a standard string object for GandiTokenInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxtGandi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$GandiToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$GandiTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # un-secure the password so we can add it to the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $GandiTokenInsecure = (New-Object PSCredential "user",$GandiToken).GetNetworkCredential().Password
    }
    $restParams = @{
        Headers = @{
            'X-Api-Key' = $GandiTokenInsecure
            Accept = 'application/json'
        }
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneName = Find-GandiZone $RecordName $restParams
    Write-Debug "Found zone $zoneName"

    # find the matching TXT record if it exists
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    $recUrl = "https://dns.api.gandi.net/api/v5/domains/$zoneName/records/$recShort/TXT"
    try {
        $rec = Invoke-RestMethod $recUrl @restParams @script:UseBasic -EA Stop
    } catch {}

    if ($rec -and "`"$TxtValue`"" -in $rec.rrset_values) {
        if ($rec.rrset_values.Count -gt 1) {
            # remove just the value we care about
            Write-Verbose "Removing $TxtValue from TXT record for $RecordName"
            $otherVals = $rec.rrset_values | Where-Object { $_ -ne "`"$TxtValue`"" }
            $body = @{rrset_values=@($otherVals)}
            Write-Debug "Sending body:`n$(($body | ConvertTo-Json))"
            $bodyJson =  $body | ConvertTo-Json -Compress
            try {
                Invoke-RestMethod $recUrl -Method Put -Body $bodyJson `
                    @restParams @script:UseBasic -EA Stop | Out-Null
            } catch { throw }
        } else {
            # delete the whole record because this value is the last one
            Write-Verbose "Removing TXT record for $RecordName"
            try {
                Invoke-RestMethod $recUrl -Method Delete `
                    @restParams @script:UseBasic -EA Stop | Out-Null
            } catch { throw }
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Gandi.

    .DESCRIPTION
        Remove a DNS TXT record from Gandi.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GandiToken
        The API token for your Gandi account. This SecureString version should only be used on Windows.

    .PARAMETER GandiTokenInsecure
        The API token for your Gandi account. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Gandi Token" -AsSecureString
        PS C:\>Remove-DnsTxtGandi '_acme-challenge.site1.example.com' 'asdfqwer12345678' $token

        Removes a TXT record using a securestring object for GandiToken. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxtGandi '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'xxxxxxxx'

        Removes a TXT record using a standard string object for GandiTokenInsecure. (Use this on non-Windows)
    #>
}

function Save-DnsTxtGandi {
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
# https://doc.livedns.gandi.net

function Find-GandiZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GandiRecordZones) { $script:GandiRecordZones = @{} }

    # check for the record in the cache
    if ($script:GandiRecordZones.ContainsKey($RecordName)) {
        return $script:GandiRecordZones.$RecordName
    }

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
            Invoke-RestMethod "https://dns.api.gandi.net/api/v5/domains/$zoneTest" `
                @RestParams @script:UseBasic -EA Stop | Out-Null
            $script:GandiRecordZones.$RecordName = $zoneTest
            return $zoneTest
        } catch {}
    }

    return $null

}
