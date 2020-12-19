function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    #Find apex domain for record
    $DomainMetadata = Find-TotalUptimeDomain -RecordName $RecordName -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if (-not $DomainMetadata) {
        throw "Unable to find TotalUptime DNS Zone for $RecordName"
    }
    Write-Debug "Found Domain ID $($DomainMetadata.id) for record $RecordName"

    #strip domain component from record
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($DomainMetadata.domainName.TrimEnd('.')))$",''
    if ($recShort -eq [string]::Empty) {
        $recShort = '@'
    }
    Write-Debug "Stripped record name to $recShort"

    $txtRecord = Find-TotalUptimeTXTRecord -DomainID $DomainMetadata.id -RecordName $recShort -TxtContent $TxtValue -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if ($txtRecord) {
        Write-Debug 'Record already exists, nothing to do'
        return
    }

    #Build Request
    $reqParams = @{
        Uri = "$TotalUptimeApiRoot/CloudDNS/Domain/$($DomainMetadata.id)/TXTRecord"
        Method = 'Post'
        Headers = @{
            Authorization  = ("Basic {0}" -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential));
            Accept         = "application/json"
            'Content-Type' = "application/x-www-form-urlencoded"
        }
        Body = @{
            txtHostName = $recShort;
            txtText     = $TxtValue;
            txtTTL      = 60;
        } | ConvertTo-Json -Compress
        Verbose = $false
        ErrorAction = 'Stop'
    }
    Write-Debug "POST $($reqParams.Uri)`n$($reqParams.Body)"
    $Response = Invoke-RestMethod @reqParams @script:UseBasic

    #failure throw error
    if ($Response.status -ne 'Success') {
        throw $Response.message
    } else {
        Write-Debug $Response.message
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to TotalUptime

    .DESCRIPTION
        Add a DNS TXT record to TotalUptime

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
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    #Find apex domain for record
    $DomainMetadata = Find-TotalUptimeDomain -RecordName $RecordName -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if (-not $DomainMetadata) {
        throw "Unable to find TotalUptime DNS Zone for $RecordName"
    }

    #Format recordname as short form
    $recShort = $RecordName -ireplace "\.?$([regex]::Escape($DomainMetadata.domainName.TrimEnd('.')))$",''
    if ($recShort -eq [string]::Empty) {
        $recShort = '@'
    }

    $txtRecord = Find-TotalUptimeTXTRecord -DomainID $DomainMetadata.id -RecordName $recShort -TxtContent $TxtValue -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot
    if (-not $txtRecord) {
        Write-Debug 'No record found, nothing to do'
        return
    }

    #Build Request
    $reqParams = @{
        Uri = "$TotalUptimeApiRoot/CloudDNS/Domain/$($DomainMetadata.id)/TXTRecord/$($txtRecord.id)"
        Method = 'Delete'
        Headers = @{
            Authorization = 'Basic {0}' -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential)
            Accept        = 'application/json'
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }

    Write-Debug "DELETE $($reqParams.Uri)"
    $Response = Invoke-RestMethod @reqParams @script:UseBasic

    # throw error on failure
    if ($Response.status -ne 'Success') {
        throw $Response.message
    } else {
        Write-Debug $Response.message
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

# Auth function
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

# Search Functions

function Find-TotalUptimeDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )

    #retrieve domains in account
    $Domains = Get-TotalUptimeDomains -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot -EA Stop
    $DomainNames = $Domains.rows.domainName

    #check if domain is in domain list
    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $domainTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        Write-Debug "Checking $domainTest"
        if ($domainTest -in $DomainNames) {
            Write-Debug "Found $domainTest"
            return $domains.rows | Where-Object domainName -eq $domainTest
        }
    }
    Write-Debug "Unable to find matching domain"
    return $null
}

function Find-TotalUptimeTXTRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtContent,
        [Parameter(Mandatory, Position = 2)]
        [string]$DomainID,
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )
    #retrieve TXT records for Domain
    $TXTRecords = Get-TotalUptimeTXTRecords -DomainID $DomainID -TotalUptimeCredential $TotalUptimeCredential -TotalUptimeApiRoot $TotalUptimeApiRoot

    #filter by name an content
    $TXTRecords.rows | Where-Object { ($_.txtHostName -eq $RecordName) -and ($_.txtText -eq $TxtContent) }
}

# API Calls

function Get-TotalUptimeDomains {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )

    #Build Request
    $reqParams = @{
        Uri = "$TotalUptimeApiRoot/CloudDNS/Domain/All"
        Headers = @{
            Authorization = 'Basic {0}' -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential)
            Accept = 'application/json'
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }

    #Execute Request
    Write-Debug "GET $($reqParams.Uri)"
    Invoke-RestMethod @reqParams @script:UseBasic
}

function Get-TotalUptimeTXTRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$DomainID,
        [pscredential]$TotalUptimeCredential,
        [string]$TotalUptimeApiRoot = 'https://api.totaluptime.com'
    )

    #Build Request
    $reqParams = @{
        Uri = "$TotalUptimeApiRoot/CloudDNS/Domain/$DomainID/TXTRecord/All"
        Headers = @{
            Authorization = ("Basic {0}" -f (ConvertTo-TotalUptimeBasicHTTPAuthString -Credential $TotalUptimeCredential));
            Accept        = "application/json"
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }

    #Execute Request
    Write-Debug "GET $($reqParams.Uri)"
    Invoke-RestMethod @reqParams @script:UseBasic
}
