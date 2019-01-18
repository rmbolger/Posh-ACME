[string]$namecomApiRootUrl = "https://api.name.com/v4"

function Add-DnsTxtNameComDns {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NameComUsername,
        [Parameter(Mandatory,Position=3)]
        [string]$NameComToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-VerboseLogEntry "name.com: Adding DNS TXT Record for $RecordName"

    Write-DebugLogEntry "RecordName: " $RecordName
    Write-DebugLogEntry "TxtValue: " $TxtValue

    $restParams = Get-RestHeaders -NameComUsername $NameComUsername -NameComUserToken $NameComToken

    # Lets make sure this domain exists and get the details (all of the records)
    $records = Find-NameComZone -RecordName $RecordName -RecordType $null -RestParams $restParams

    # Did we find a valid domain?
    if ($records -ne $null -and $records.Length -gt 0)
    {
        # Lets use the domain name that name.com indicates is the "root"
        $domainName = $records[0].domainName
        $RecordName = $RecordName.Replace(".$domainName","");

        Write-VerboseLogEntry "Valid Domain Found.  Adding a TXT record for $RecordName with value $TxtValue"

        # add new record
        try {
            $ApiUrl = "$namecomApiRootUrl/domains/$domainName/records"
            Write-DebugLogEntry "Domain Create API URL: " $ApiUrl

            $bodyJson = @{host="$RecordName";type="TXT";answer="$TxtValue";ttl=300} | ConvertTo-Json -Compress
            Write-DebugLogEntry "Domain Create API JSON: " $bodyJson

            Invoke-RestMethod $ApiUrl -Method Post -Body $bodyJson @restParams @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        Write-Host "Unknown Domain"
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to NameComDns.

    .DESCRIPTION
        Add a DNS TXT record to NameComDns.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NameComUsername
        The account API username. 

    .PARAMETER NameComToken
        The account API token. 
		
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtNameComDns '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'username' 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtNameComDns {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NameComUsername,
        [Parameter(Mandatory,Position=3)]
        [string]$NameComToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-VerboseLogEntry "name.com: Removing DNS TXT Record for $RecordName"

    Write-DebugLogEntry "RecordName: " $RecordName
    Write-DebugLogEntry "TxtValue: " $TxtValue
    
    $restParams = Get-RestHeaders -NameComUsername $NameComUsername -NameComUserToken $NameComToken

    # Lets make sure this domain exists and get the details (all of the records)
    $records = Find-NameComZone -RecordName $RecordName -RecordType "TXT" -RestParams $restParams

    # Search for the record we care about
    $srvRecord = $records | ? { $_.answer -eq $TxtValue }

    if ($srvRecord -eq $null -or $srvRecord.Length -eq 0) {
        Write-VerboseLogEntry "Unknown Domain TXT Record"

        return;
    }

    $srvRecord | % {
        # remove record
        try {
            $id = $_.id
            $domainName = $_.domainName

            Write-VerboseLogEntry "Existing Record Found. Removing TXT record $id for $RecordName with value $TxtValue"

            $ApiUrl = "$namecomApiRootUrl/domains/$domainName/records/$id"
            Write-DebugLogEntry "Domain Delete API URL: " $ApiUrl

            Invoke-RestMethod $ApiUrl -Method Delete @restParams @script:UseBasic | Out-Null
        } catch { throw }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from NameComDns.

    .DESCRIPTION
        Remove a DNS TXT record from NameComDns.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NameComUsername
        The account API username. 

    .PARAMETER NameComToken
        The account API token. 

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtNameComDns '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'username' 'xxxxxxxxxxxx'

        Remove a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtNameComDns {
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
# https://www.name.com/api-docs/DNS

function Find-NameComZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Position=1)]
        [string]$RecordType = $null,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$RestParams
    )

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
        #$url = Get-RootDomain -Domain $url

        $url = "$namecomApiRootUrl/domains/$RecordName/records"
        
        Write-DebugLogEntry "Domain Get API URL: " $url

        $entries = (Invoke-RestMethod $url @RestParams @script:UseBasic).records

        Write-DebugLogEntry "Domain Get API Results: " $entries

        if ($RecordType -ne $null -and $RecordType.Length -gt 0) {
            return $entries | ? { $_.type -eq $RecordType }
        }  
        
        return $entries 
    } catch { throw }

    return $null
}

function Get-RestHeaders {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$NameComUsername,
        [Parameter(Mandatory,Position=1)]
        [string]$NameComUserToken
    )

    #Write-DebugLogEntry "UserName: " $NameComUsername
    #Write-DebugLogEntry "Token: " $NameComUserToken

    $restParams = @{
        Headers = @{
            Accept='application/json'
            Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $NameComUserName,$NameComToken)))
        }
        ContentType = 'application/json'
    }

    return $restParams
}

function Get-RootDomain {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$domain
    )

    $result = $domain.Substring($domain.IndexOf(".") + 1)
    # A hack to check to see if we got a TLD instead of the root domain
    if (!$result.Contains(".")) { $result = $domain }

    return $result
}

function Write-DebugLogEntry {
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    #Write-Host $ExtraParams
}

function Write-VerboseLogEntry {
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    #Write-Host $ExtraParams -ForegroundColor Yellow
}

