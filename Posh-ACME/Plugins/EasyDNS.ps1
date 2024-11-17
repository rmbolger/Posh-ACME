function Get-CurrentPluginType { 'dns-01' }

Function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$EDToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$EDKeySecure,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$EDKey,
        [switch]$EDUseSandbox,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # set the API base
    $apiBase = if ($EDUseSandbox) { "https://sandbox.rest.easydns.net" } else { "https://rest.easydns.net" }

    # grab the plain text key
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $EDKey = [pscredential]::new('a',$EDKeySecure).GetNetworkCredential().Password
    }

    # create the basic auth header
    $encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($EDToken):$($EDKey)"))
    $Headers = @{ Authorization = "Basic $encodedCreds" }

    # find the domain/zone associated with this record
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        try {
            $Records = Invoke-RestMethod "$apiBase/zones/records/all/$($zoneTest)?format=json" `
                -ContentType 'application/json' -Headers $Headers -Method GET @script:UseBasic -EA Stop
        } catch { continue }
        $zoneName = $zoneTest
        Write-Verbose "Found $zoneName zone"
        break
    }
    if (-not $zoneName) { throw "Unable to find zone for $RecordName" }

    # grab the relative portion of the fqdn
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''

    # check for existing record
    $rec = $Records.data | Where-Object { $_.type -eq 'TXT' -and $_.host -eq $recShort -and $_.rData -eq $TxtValue }
    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # add it
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        $body = @{
            host = $recShort
            domain = $zoneName
            ttl = 0
            prio = 0
            type = "txt"
            rdata = $TxtValue
        } | ConvertTo-Json
        Write-Debug $body

        Invoke-RestMethod "$apiBase/zones/records/add/$zoneName/txt?format=json" -Method Put `
            -Body $body -ContentType 'application/json' -Headers $Headers @script:UseBasic | Out-Null
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to EasyDNS.

    .DESCRIPTION
        Add a DNS TXT record to EasyDNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER EDToken
        The EasyDNS API Token.

    .PARAMETER EDKeySecure
        The EasyDNS API Key.

    .PARAMETER EDKey
        (DEPRECATED) The EasyDNS API Key.

    .PARAMETER EDUseSandbox
        If specified, the plugin runs against the Sandbox environment instead of the Live environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host 'Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' -EDToken 'xxxxxxxx' -EDKey $key

        Adds a TXT record for the specified site with the specified value.
    #>
}

Function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$EDToken,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$EDKeySecure,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$EDKey,
        [switch]$EDUseSandbox,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # set the API base
    $apiBase = if ($EDUseSandbox) { "https://sandbox.rest.easydns.net" } else { "https://rest.easydns.net" }

    # grab the plain text key
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $EDKey = [pscredential]::new('a',$EDKeySecure).GetNetworkCredential().Password
    }

    # create the basic auth header
    $encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($EDToken):$($EDKey)"))
    $Headers = @{ Authorization = "Basic $encodedCreds" }

    # find the domain/zone associated with this record
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        try {
            $Records = Invoke-RestMethod "$apiBase/zones/records/all/$($zoneTest)?format=json" `
                -ContentType 'application/json' -Headers $Headers -Method GET @script:UseBasic -EA Stop
        } catch { continue }
        $zoneName = $zoneTest
        Write-Verbose "Found $zoneName zone"
        break
    }
    if (-not $zoneName) { throw "Unable to find zone for $RecordName" }

    # grab the relative portion of the fqdn
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''

    # check for existing record
    $rec = $Records.data | Where-Object { $_.type -eq 'TXT' -and $_.host -eq $recShort -and $_.rData -eq $TxtValue }
    if ($rec) {
        # remove it
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        Invoke-RestMethod "$apiBase/zones/records/$zoneName/$($rec.id)?format=json" -Method Delete `
            -ContentType 'application/json' -Headers $Headers @script:UseBasic | Out-Null
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record to EasyDNS.

    .DESCRIPTION
        Remove a DNS TXT record to EasyDNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER EDToken
        The EasyDNS API Token.

    .PARAMETER EDKeySecure
        The EasyDNS API Key.

    .PARAMETER EDKey
        (DEPRECATED) The EasyDNS API Key.

    .PARAMETER EDUseSandbox
        If specified, the plugin runs against the Sandbox environment instead of the Live environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host 'Key' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txtvalue' -EDToken 'xxxxxxxx' -EDKey $key

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

# API Docs
# http://docs.sandbox.rest.easydns.net/
# http://sandbox.rest.easydns.net:3000/
