function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [pscredential]$LuaCredential,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$LuaUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$LuaPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # create a pscredential from insecure args if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secpass = ConvertTo-SecureString $LuaPassword -AsPlainText -Force
        $LuaCredential = New-Object PSCredential ($LuaUsername,$secpass)
    }

    $apiRoot = 'https://api.luadns.com/v1'
    $restParams = @{
        Headers = @{Accept='application/json'}
        ContentType = 'application/json'
        Credential = $LuaCredential
    }

    # get the zone name for our record
    $zoneID = Find-LuaZone $RecordName $restParams
    Write-Debug "Found zone $zoneID"

    # Search for the record we care about
    try {
        $rec = (Invoke-RestMethod "$apiRoot/zones/$zoneID/records" @restParams @script:UseBasic) |
            Where-Object { $_.name -eq "$RecordName." -and $_.type -eq 'TXT' -and $_.content -eq $TxtValue }
    } catch { throw }

    if (-not $rec) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $bodyJson = @{name="$RecordName.";type='TXT';content=$TxtValue;ttl=10} | ConvertTo-Json -Compress
            Invoke-RestMethod "$apiRoot/zones/$zoneID/records" -Method Post -Body $bodyJson `
                @restParams @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to LuaDns.

    .DESCRIPTION
        Add a DNS TXT record to LuaDns.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LuaCredential
        A PSCredential object containing the account email address as the username and API token as the password. This PSCredential option should only be used from Windows.

    .PARAMETER LuaUsername
        The account email address. This should be used from non-Windows.

    .PARAMETER LuaPassword
        The account API token. This should be used from non-Windows.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' (Get-Credential)

        Adds a TXT record for the specified site with the specified value from Windows.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user@example.com' 'password'

        Adds a TXT record for the specified site with the specified value from non-Windows.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [pscredential]$LuaCredential,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$LuaUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$LuaPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # create a pscredential from insecure args if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secpass = ConvertTo-SecureString $LuaPassword -AsPlainText -Force
        $LuaCredential = New-Object PSCredential ($LuaUsername,$secpass)
    }

    $apiRoot = 'https://api.luadns.com/v1'
    $restParams = @{
        Headers = @{Accept='application/json'}
        ContentType = 'application/json'
        Credential = $LuaCredential
    }

    # get the zone name for our record
    $zoneID = Find-LuaZone $RecordName $restParams
    Write-Debug "Found zone $zoneID"

    # Search for the record we care about
    try {
        $rec = (Invoke-RestMethod "$apiRoot/zones/$zoneID/records" @restParams @script:UseBasic) |
            Where-Object { $_.name -eq "$RecordName." -and $_.type -eq 'TXT' -and $_.content -eq $TxtValue }
    } catch { throw }

    if (-not $rec) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            Invoke-RestMethod "$apiRoot/zones/$zoneID/records/$($rec.id)" -Method Delete `
                @restParams @script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from LuaDns.

    .DESCRIPTION
        Remove a DNS TXT record from LuaDns.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LuaCredential
        A PSCredential object containing the account email address as the username and API token as the password. This PSCredential option should only be used from Windows.

    .PARAMETER LuaUsername
        The account email address. This should be used from non-Windows.

    .PARAMETER LuaPassword
        The account API token. This should be used from non-Windows.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' (Get-Credential)

        Removes a TXT record for the specified site with the specified value from Windows.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user@example.com' 'password'

        Remove a TXT record for the specified site with the specified value from non-Windows.
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
# http://www.luadns.com/api.html

function Find-LuaZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:LuaRecordZones) { $script:LuaRecordZones = @{} }

    # check for the record in the cache
    if ($script:LuaRecordZones.ContainsKey($RecordName)) {
        return $script:LuaRecordZones.$RecordName
    }

    $apiRoot = 'https://api.luadns.com/v1'

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    # get the list of zones
    try {
        $zones = Invoke-RestMethod "$apiRoot/zones" @RestParams @script:UseBasic
    } catch { throw }

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        if ($zoneTest -in $zones.name) {
            $zoneID = ($zones | Where-Object { $_.name -eq $zoneTest }).id
            $script:LuaRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null

}
