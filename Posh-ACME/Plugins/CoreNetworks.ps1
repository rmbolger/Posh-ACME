function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$CoreNetworksCred,
        [string]$CoreNetworksApiRoot = 'https://beta.api.core-networks.de',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    ### Authentication at the API via authentication token, which must be sent in the header of every request.
    $headers = @{
        Authorization="Bearer $(Auth-CoreNetworks $CoreNetworksApiRoot $CoreNetworksCred)"
    }
    Write-Debug $headers

    ### Search und find the dns zone of the (sub)domain  (for example: example.com).
    $CoreNetworkDnsZone = $(Find-CoreNetworksDnsZones $CoreNetworksApiRoot $headers $RecordName)
    Write-Debug $CoreNetworkDnsZone

    ### Grab the relative portion of the Fully Qualified Domain Name (FQDN)
    $DnsTxtName = ($RecordName -ireplace [regex]::Escape($CoreNetworkDnsZone), [string]::Empty).TrimEnd('.')
    Write-Debug $DnsTxtName

    ### Build the dns record
    $JsonBody = @{
        name = $DnsTxtName
        ttl  = 60
        type = "TXT"
        data = "`"$TxtValue`""

    } | ConvertTo-Json
    Write-Debug $JsonBody

    ### Send a POST request including bearer authentication.
    try {
        Invoke-RestMethod -Method Post -Headers $headers -Body $JsonBody -ContentType "application/json" -Uri "$CoreNetworksApiRoot/dnszones/$CoreNetworkDnsZone/records/" -ErrorAction Stop @script:UseBasic | Out-Null
    }
    catch {
        Write-Debug $_
        throw
    }

    ### Save changes in the dns zone
    $(Commit-CoreNetworks $CoreNetworksApiRoot $headers $CoreNetworkDnsZone)


    <#
    .SYNOPSIS
        Add a DNS TXT record to CoreNetworks.

    .DESCRIPTION
        Add a DNS TXT record to CoreNetworks.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CoreNetworksCred
        The API username and password required to authenticate.

    .PARAMETER CoreNetworksApiRoot
        The root URL of the API. Defaults to https://beta.api.core-networks.de

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' -CoreNetworksCred (Get-Credential)

        Adds a TXT record using credentials and ignores certificate validation.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$CoreNetworksCred,
        [string]$CoreNetworksApiRoot = 'https://beta.api.core-networks.de',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    ### Authentication at the API via authentication token, which must be sent in the header of every request.
    $headers = @{
        Authorization="Bearer $(Auth-CoreNetworks $CoreNetworksApiRoot $CoreNetworksCred)"
    }
    Write-Debug $headers

    ### Search und find the dns zone of the (sub)domain  (for example: example.com).
    $CoreNetworkDnsZone = $(Find-CoreNetworksDnsZones $CoreNetworksApiRoot $headers $RecordName)
    Write-Debug $CoreNetworkDnsZone

    ### Grab the relative portion of the Fully Qualified Domain Name (FQDN)
    $DnsTxtName = ($RecordName -ireplace [regex]::Escape($CoreNetworkDnsZone), [string]::Empty).TrimEnd('.')
    Write-Debug $DnsTxtName

    ### Build the dns record
    $JsonBody = @{
        name = $DnsTxtName
        data = "`"$TxtValue`""

    } | ConvertTo-Json
    Write-Debug $JsonBody


    ### Send a POST request including bearer authentication.
    try {
        Invoke-RestMethod -Method Post -Headers $headers -Body $JsonBody -ContentType "application/json" -Uri "$CoreNetworksApiRoot/dnszones/$CoreNetworkDnsZone/records/delete" -ErrorAction Stop @script:UseBasic | Out-Null
    }
    catch {
        Write-Debug $_
        throw
    }

    ### Save changes in the dns zone
    $(Commit-CoreNetworks $CoreNetworksApiRoot $headers $CoreNetworkDnsZone)

    <#
    .SYNOPSIS
        Add a DNS TXT record to CoreNetworks.

    .DESCRIPTION
        Add a DNS TXT record to CoreNetworks.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CoreNetworksCred
        The API username and password required to authenticate.

    .PARAMETER CoreNetworksApiRoot
        The root URL of the API. Defaults to https://beta.api.core-networks.de

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -CoreNetworksCred (Get-Credential)

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
# https://beta.api.core-networks.de/doc/


### To get a token, you need an API user account. You can set this up in the API user account management in our web interface.
function Auth-CoreNetworks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$ApiRootUrl,
        [Parameter(Mandatory, Position=1)]
        [pscredential]$Cred
    )

    ### Send a POST request including bearer authentication.
    try {
        $data = Invoke-RestMethod -Method Post -Body "{`"login`":`"$($Cred.GetNetworkCredential().UserName)`",`"password`":`"$($Cred.GetNetworkCredential().Password)`"}" `
        -ContentType "application/json" -Uri "$ApiRootUrl/auth/token" -ErrorAction Stop @script:UseBasic

        return $data.token
    }
    catch {
        Write-Debug $_
        throw
    }
}


### With the following function you get a list of all DNS zones that you currently have.
function Find-CoreNetworksDnsZones {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [System.Object]$ApiRootUrl,
        [Parameter(Mandatory, Position=1)]
        [string]$Header,
        [Parameter(Mandatory, Position=2)]
        [string]$RecordName
    )

    ### Send a POST request including bearer authentication.
    try {
        $data = Invoke-RestMethod -Method Get -Headers $headers -ContentType "application/json" -Uri "$ApiRootUrl/dnszones/" -ErrorAction Stop @script:UseBasic

        foreach ($e in $data.name) {
            if ($RecordName -match $e ) {
                return $e
            }
        }
    }
    catch {
        Write-Debug $_
        throw
    }
}

### Our current backend for the name server is not suitable for the high-frequency processing of DNS records. So that you can make
### major changes to DNS zones quickly without having to wait for the name server, changes to the DNS records are not transmitted
### to the name servers immediately. Instead, when you are done changing DNS records, you must commit the zone.
function Commit-CoreNetworks {
    [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position = 0)]
            [string]$ApiRootUrl,
            [Parameter(Mandatory, Position = 1)]
            [string]$Header,
            [Parameter(Mandatory, Position = 2)]
            [string]$DnsZone
        )

    ### Send a POST request including bearer authentication.
    try {
        Invoke-RestMethod -Method Post -Headers $headers -ContentType "application/json" -Uri "$ApiRootUrl/dnszones/$DnsZone/records/commit" -ErrorAction Stop @script:UseBasic | Out-Null
    }
    catch {
        Write-Debug $_
        throw
    }
}
