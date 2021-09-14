function Get-CurrentPluginType { 'dns-01' }


function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$CoreNetworksApiRoot,
        [Parameter(Mandatory, ParameterSetName='Secure')]
        [pscredential]$CoreNetworksCred,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    ### Authentication at the API via authentication token, which must be sent in the header of every request. 
    $headers = @{
        Authorization="Bearer $(Auth-CoreNetworks $CoreNetworksApiRoot $CoreNetworksCred)"
    }

    ### Search und find the dns zone of the (sub)domain  (for example: example.com).
    $CoreNetworkDnsZone = $(Find-CoreNetworksDnsZones $CoreNetworksApiRoot $headers $RecordName)

    ### Remove the dns zone name from Record Name (for example example.com).
    $DnsTxtName = "$($RecordName.Replace(`".$CoreNetworkDnsZone`", `"`"))" 

    ### Build the dns record
    $JsonBody = @{
        name = $DnsTxtName
        ttl  = 60
        type = "TXT"
        data = "`"$TxtValue`""

    } | ConvertTo-Json


    ### Send a POST request including bearer authentication.
    try {
        Invoke-RestMethod -Method Post -Headers $headers -Body $JsonBody -ContentType "application/json" -Uri "$CoreNetworksApiRoot/dnszones/$CoreNetworkDnsZone/records/"
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

    .PARAMETER CoreNetworksApiRoot
        The root URL of the Simple DNS Plus Server API. For example, https://beta.api.core-networks.de/dnszones/example.com/records/

    .PARAMETER CoreNetworksCred
        The HTTP API credentials required to authenticate.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pArgs = @{ CoreNetworksApiRoot = 'https://beta.api.core-networks.de'; CoreNetworksCred = (Get-Credential) }
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' @pArgs
        Adds a TXT record using credentials and ignores certificate validation.

    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$CoreNetworksApiRoot,
        [Parameter(Mandatory, ParameterSetName='Secure')]
        [pscredential]$CoreNetworksCred,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    ### Authentication at the API via authentication token, which must be sent in the header of every request. 
    $headers = @{
        Authorization="Bearer $(Auth-CoreNetworks $CoreNetworksApiRoot $CoreNetworksCred)"
    }

    ### Search und find the dns zone of the (sub)domain  (for example: example.com).
    $CoreNetworkDnsZone = $(Find-CoreNetworksDnsZones $CoreNetworksApiRoot $headers $RecordName)

    ### Remove the dns zone name from Record Name (for example example.com).
    $DnsTxtName = "$($RecordName.Replace(`".$CoreNetworkDnsZone`", `"`"))" 

    ### Build the dns record
    $JsonBody = @{
        name = $DnsTxtName
        data = "`"$TxtValue`""

    } | ConvertTo-Json


    ### Send a POST request including bearer authentication.
    try {
        Invoke-RestMethod -Method Post -Headers $headers -Body $JsonBody -ContentType "application/json" -Uri "$CoreNetworksApiRoot/dnszones/$CoreNetworkDnsZone/records/delete"
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

    .PARAMETER CoreNetworksApiRoot
        The root URL of the Simple DNS Plus Server API. For example, https://beta.api.core-networks.de/dnszones/example.com/records/

    .PARAMETER CoreNetworksCred
        The HTTP API credentials required to authenticate.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, just
    # leave the function body empty.

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications.
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
        -ContentType "application/json" -Uri "$ApiRootUrl/auth/token"

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
        $data = Invoke-RestMethod -Method Get -Headers $headers -ContentType "application/json" -Uri "$ApiRootUrl/dnszones/"

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
        Invoke-RestMethod -Method Post -Headers $headers -ContentType "application/json" -Uri "$ApiRootUrl/dnszones/$DnsZone/records/commit"
        
    }
    catch {
        Write-Debug $_
        throw
    }
}
