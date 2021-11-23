function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Do work here to add the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    #Find apex domain for record
    $DomainMetadata = Find-TotalUptimeDomain -RecordName $RecordName -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if (-not $DomainMetadata){
        throw "Unable to find TotalUptime DNS Zone for $RecordName"
    }
    Write-Debug "Found Domain ID $($DomainMetadata.id) for record $RecordName"

    #strip domain component from record
    $recShort = ($RecordName -ireplace [regex]::Escape($DomainMetadata.domainName), [string]::Empty).TrimEnd('.')

    if ($recShort -eq [string]::Empty) {
        $recShort = '@'
    }

    $DomainID = $DomainMetadata.id

    #Build Request
    $RequestUri = "$TotalUptimeApiRoot/CloudDNS/Domain/$DomainID/TXTRecord"
    $RequestHeaders = @{
        Authorization=("Basic {0}" -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential));
        Accept="application/json"
        'Content-Type'="application/x-www-form-urlencoded"
    }
    $RequestBody = @{
        txtHostName=$recShort;
        txtText=$TxtValue;
        txtTTL=60;
    }
    Write-Debug $RequestUri
    $Response = Invoke-RestMethod -Method Post -Uri $RequestUri -Headers $RequestHeaders -Body ($RequestBody | ConvertTo-Json -Compress) @script:UseBasic

    #failure throw error
    if ($Response.status -ne 'Success'){
        throw $Response.message
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to TotalUptime

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER TotalUptimeCredential
        The API username and password required to authenticate.
    
    .PARAMETER TotalUptimeApiRoute
        The API root URL. defaults to https://api.totaluptime.com

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -TotalUptimeCredential (Get-Credential)

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )


    #Find apex domain for record
    $DomainMetadata = Find-TotalUptimeDomain -RecordName $RecordName -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if (-not $DomainMetadata){
        throw "Unable to find TotalUptime DNS Zone for $RecordName"
    }

    #Format recordname as short form
    $recShort = ($RecordName -ireplace [regex]::Escape($DomainMetadata.domainName), [string]::Empty).TrimEnd('.')
    if ($recShort -eq [string]::Empty) {
        $recShort = '@'
    }

    $txtRecord = Find-TotalUptimeTXTRecord -DomainID $DomainMetadata.id -RecordName $recShort -TxtContent $TxtValue -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if (-not $txtRecord){
        Write-Debug 'No record found, nothing to do'
    }else{
        $RecordID = $txtRecord.id
        $DomainID = $DomainMetadata.id
        #Build Request
        $RequestUri = "$TotalUptimeApiRoot/CloudDNS/Domain/$DomainID/TXTRecord/$RecordID"
        $RequestHeaders = @{
            Authorization=("Basic {0}" -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential));
            Accept="application/json"
        }
    
        $Response = Invoke-RestMethod -Method Delete -Uri $RequestUri -Headers $RequestHeaders
        
        if ($Response.status -ne 'Success'){
            throw $Response.message
        }
    }




    <#
    .SYNOPSIS
        Remove a DNS TXT record from TotalUptime

    .DESCRIPTION
        Remove a DNS TXT record from TotalUptime

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER TotalUptimeCredential
        The API username and password required to authenticate.
    
    .PARAMETER TotalUptimeApiRoute
        The API root URL. defaults to https://api.totaluptime.com

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -TotalUptimeCredential (Get-Credential)

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

# API Documentation
# https://totaluptime.com/api/v2/

function ConvertTo-TotalUptimeBasicHTTPAuthString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
        )
    #Converts a PSCredential Object to a HTTP Basic Auth String
    $base64AuthString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Password)))
    return $base64AuthString
}

function Find-TotalUptimeDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )

    $Domains = Get-TotalUptimeDomains -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot

    $DomainNames = $Domains.rows.domainName

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $domainTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $domainTest"
        if ($domainTest -in $DomainNames){
            return $domains.rows | Where-Object domainName -eq $domainTest
        }
    }
    return $null
}

function Find-TotalUptimeTXTRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtContent,
        [Parameter(Mandatory,Position=2)]
        [string]$DomainID,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )
    $TXTRecords = Get-TotalUptimeTXTRecords -DomainID $DomainID -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot

    return $TXTRecords.rows | Where-Object {($_.txtHostName -eq $RecordName) -and ($_.txtText -eq $TxtContent)}
    
}


function Get-TotalUptimeDomains{
    param(
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )

    #Build Request
    $RequestUri = "$TotalUptimeApiRoot/CloudDNS/Domain/All"
    $RequestHeaders = @{
        Authorization=("Basic {0}" -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential));
        Accept="application/json"
    }
    
    #Execute Request
    $Response = Invoke-RestMethod -Method Get -Uri $RequestUri -Headers $RequestHeaders @script:UseBasic
    
    return $Response

}

function Get-TotalUptimeTXTRecords{
    param(
        [parameter(Mandatory = $true)]$DomainID,
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )
    
    #Build Request
    $RequestUri = "$TotalUptimeApiRoot/CloudDNS/Domain/$DomainID/TXTRecord/All"
    $RequestHeaders = @{
        Authorization=("Basic {0}" -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential));
        Accept="application/json"
    }

    $Response = Invoke-RestMethod -Method Get -Uri $RequestUri -Headers $RequestHeaders @script:UseBasic

    return $Response
}

