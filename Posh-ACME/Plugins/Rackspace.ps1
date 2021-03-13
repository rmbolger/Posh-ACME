function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$RSUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$RSApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$RSApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-RackspaceDns @PSBoundParameters

    # get the zone name for our record
    $zoneID,$zoneName = Find-RSZone $RecordName
    Write-Debug "Found zone $zoneID for $zoneName"

    $zoneRoot = "$($script:RSAuth.dnsBase)/domains/$zoneID"
    $restParams = @{
        Headers = @{'X-Auth-Token'=$script:RSAuth.token}
        ContentType = 'application/json'
    }

    # attempt to find the existing record(s)
    try {
        $response = Invoke-RestMethod "$zoneRoot/records?type=TXT&name=$RecordName" `
             @restParams @script:UseBasic
        $recs = $response.records
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $bodyJson = @{records = @( @{
                name=$RecordName
                type='TXT'
                data=$TxtValue
                ttl=300
            })} | ConvertTo-Json -Compress
            Invoke-RestMethod "$zoneRoot/records" -Method Post -Body $bodyJson `
                @restParams @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Rackspace Cloud DNS

    .DESCRIPTION
        Add a DNS TXT record to Rackspace Cloud DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RSUsername
        The username of your Rackspace Cloud account.

    .PARAMETER RSApiKey
        The API Key associated with your Rackspace Cloud account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER RSApiKeyInsecure
        The API Key associated with your Rackspace Cloud account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "Rackspace API Key" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'myusername' $key

        Adds a TXT record using a securestring object for RSApiKey. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'myusername' 'key'

        Adds a TXT record using a standard string object for RSApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$RSUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$RSApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$RSApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-RackspaceDns @PSBoundParameters

    # get the zone name for our record
    $zoneID,$zoneName = Find-RSZone $RecordName
    Write-Debug "Found zone $zoneID for $zoneName"

    $zoneRoot = "$($script:RSAuth.dnsBase)/domains/$zoneID"
    $restParams = @{
        Headers = @{'X-Auth-Token'=$script:RSAuth.token}
        ContentType = 'application/json'
    }

    # attempt to find the existing record(s)
    try {
        $response = Invoke-RestMethod "$zoneRoot/records?type=TXT&name=$RecordName" `
             @restParams @script:UseBasic
        $recs = $response.records
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $recID = ($recs | Where-Object { $_.data -eq $TxtValue }).id
            Invoke-RestMethod "$zoneRoot/records/$recID" -Method Delete `
                @restParams @script:UseBasic | Out-Null
        } catch { throw }
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Rackspace Cloud DNS

    .DESCRIPTION
        Remove a DNS TXT record from Rackspace Cloud DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RSUsername
        The username of your Rackspace Cloud account.

    .PARAMETER RSApiKey
        The API Key associated with your Rackspace Cloud account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER RSApiKeyInsecure
        The API Key associated with your Rackspace Cloud account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "Rackspace API Key" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'myusername' $key

        Removes a TXT record using a securestring object for RSApiKey. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'myusername' 'key'

        Removes a TXT record using a standard string object for RSApiKeyInsecure. (Use this on non-Windows)
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

function Connect-RackspaceDns {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RSUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=1)]
        [securestring]$RSApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=1)]
        [string]$RSApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # return if we already have a valid Bearer token
    if ($script:RSAuth -and (Get-DateTimeOffsetNow) -lt $script:RSAuth.expires) { return }

    # decrypt the secure password so we can put it in the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $RSApiKeyInsecure = (New-Object PSCredential "user",$RSApiKey).GetNetworkCredential().Password
    }

    # create the authentication object we need to send
    # https://developer.rackspace.com/docs/cloud-dns/quickstart/
    $rsAuthBody = @{
        auth = @{
            'RAX-KSKEY:apiKeyCredentials' = @{
                username = $RSUsername
                apiKey = $RSApiKeyInsecure
            }
        }
    } | ConvertTo-Json -Compress

    # authenticate
    try {
        $response = Invoke-RestMethod 'https://identity.api.rackspacecloud.com/v2.0/tokens' `
            -Method Post -ContentType 'application/json' -Body $rsAuthBody @script:UseBasic
        Write-Debug "Rackspace Response: `n$($response | ConvertTo-Json)"
    } catch { throw }

    # save what we care about to a script variable
    if ($response.access) {
        $response.access.token.expires = Repair-ISODate $response.access.token.expires
        $script:RSAuth = @{
            token = $response.access.token.id
            dnsBase = ($response.access.serviceCatalog | Where-Object { $_.name -eq 'cloudDNS' })[0].endpoints.publicURL
            expires = [DateTimeOffset]::Parse($response.access.token.expires).AddMinutes(-5)
        }
    } else {
        throw "Unexpected authentication response from Rackspace API. Enable debug output for details."
    }

}

function Find-RSZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:RSRecordZones) { $script:RSRecordZones = @{} }

    # check for the record in the cache
    if ($script:RSRecordZones.ContainsKey($RecordName)) {
        return $script:RSRecordZones.$RecordName
    }

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com
    $apiRoot = $script:RSAuth.dnsBase

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-RestMethod "$apiRoot/domains?name=$zoneTest" @script:UseBasic `
                -Headers @{'X-Auth-Token'=$script:RSAuth.token} -ContentType 'application/json'
            if ($response.totalEntries -gt 0) {
                $z = $response.domains[0]
                $script:RSRecordZones.$RecordName = $z.id,$z.name
                return $z.id,$z.name
            }
        } catch { throw }
    }

    return $null
}
