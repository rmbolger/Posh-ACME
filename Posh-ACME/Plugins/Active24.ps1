function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$A24Token,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $A24TokenInsecure = [pscredential]::new('a',$A24Token).GetNetworkCredential().Password

    $apiRoot = 'https://api.active24.com'
    $restParams = @{
        Headers = @{Authorization="Bearer $A24TokenInsecure"}
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneName = Find-A24Zone $RecordName $restParams
    if ([String]::IsNullOrWhiteSpace($zoneName)) {
        throw "Unable to find zone for $RecordName in account $acctID"
    }
    Write-Debug "Found zone $zoneName"

    # get all the instances of the record
    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        $recs = (Invoke-RestMethod "$apiRoot/dns/$zoneName/records/v1" @restParams -Method Get) | ? {$_.name -eq $recShort -and $_.type -eq "TXT"}
    } catch { throw }

    if ($recs.Count -eq 0 -or $TxtValue -notin $recs.text) {
        # add new record
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            $bodyJson = @{name=$recShort;text=$TxtValue;ttl=300} | ConvertTo-Json -Compress
            Invoke-RestMethod "$apiRoot/dns/$zoneName/txt/v1" -Method Post -Body $bodyJson @restParams | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Active24.

    .DESCRIPTION
        Add a DNS TXT record to Active24

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER A24Token
        The access API token for Active24

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Active24 Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds a TXT record for the specified site with the specified value on Windows.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$A24Token,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $A24TokenInsecure = [pscredential]::new('a',$A24Token).GetNetworkCredential().Password

    $apiRoot = 'https://api.active24.com'
    $restParams = @{
        Headers = @{Authorization="Bearer $A24TokenInsecure"}
        ContentType = 'application/json'
    }

    # get the zone name for our record
    $zoneName = Find-A24Zone $RecordName $restParams
    if ([String]::IsNullOrWhiteSpace($zoneName)) {
        throw "Unable to find zone for $RecordName in account $acctID"
    }
    Write-Debug "Found zone $zoneName"

    # get all the instances of the record
    try {
        $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
        $recs = (Invoke-RestMethod "$apiRoot/dns/$zoneName/records/v1" @restParams -Method Get) | ? {$_.name -eq $recShort -and $_.type -eq "TXT"}
    } catch { throw }

    if ($recs.Count -eq 0 -or $TxtValue -notin $recs.text) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # delete record
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            $recID = ($recs | Where-Object { $_.text -eq $TxtValue }).hashId
            Invoke-RestMethod "$apiRoot/dns/$zoneName/$recID/v1" -Method Delete @restParams | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Active24.

    .DESCRIPTION
        Remove a DNS TXT record from Active24.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER A24Token
        The access API token for Active24.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host "Active24 Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes a TXT record for the specified site with the specified value on Windows.
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
# https://api.active24.com/swagger-ui.html

function Find-A24Zone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:A24RecordZones) { $script:A24RecordZones = @{} }

    # check for the record in the cache
    if ($script:A24RecordZones.ContainsKey($RecordName)) {
        return $script:A24RecordZones.$RecordName
    }

    $apiRoot = 'https://api.active24.com'

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
            $queryParams = @{
                Uri = '{0}/dns/{1}/records/v1' -f $apiRoot,$zoneTest
                Method = 'GET'
                Headers = $RestParams.Headers
                ContentType = $RestParams.ContentType
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "GET $($queryParams.Uri)"
            # if the call succeeds, the zone exists, so we don't care about the actual response
            $resp = Invoke-RestMethod @queryParams @script:UseBasic
            Write-Debug "Response`n$($resp | ConvertTo-Json -Dep 10)"
            $script:A24RecordZones.$RecordName = $zoneTest
            return $zoneTest
        } catch {
            Write-Debug ($_.ToString())
        }
    }

    return $null

}
