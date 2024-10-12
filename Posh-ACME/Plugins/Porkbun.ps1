function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string] $RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string] $TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [SecureString] $PorkbunAPIKey,
        [Parameter(Mandatory, Position = 3)]
        [SecureString] $PorkbunSecret,
        [string] $PorkbunAPIHost = 'api.porkbun.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    [string] $APIKey = [PSCredential]::new('Username', $PorkbunAPIKey).GetNetworkCredential().Password
    [string] $APISecret = [PSCredential]::new('Username', $PorkbunSecret).GetNetworkCredential().Password

    $domainQuery = @{
        LongName = $RecordName
        PorkbunAPIKey = $APIKey
        PorkbunSecret = $APISecret
        PorkbunAPIHost = $PorkbunAPIHost
    }
    $DomainInfo = Get-PorkbunDomainInfo @domainQuery

    # Get the portion of the full name that is the domain name (e.g. 'record.name.sub.example.com' will become 'example.com')
    [string] $DomainName = $DomainInfo.Domain
    # Get the portion of the full name that will become the record name (e.g. 'record.name.sub.example.com' will become 'record.name.sub')
    [string] $RecordNameShort = ($RecordName -ireplace [Regex]::Escape($DomainName), [string]::Empty).TrimEnd('.')

    # Get any existing TXT record(s) that already match what we want to create
    [object[]] $EqualRecords = @($DomainInfo.Records | Where-Object { ($_.type -EQ 'TXT') -AND ($_.name -eq $RecordName) -AND ($_.content -EQ $TxtValue) })

    if ($EqualRecords.Count -EQ 0)
    {
        Write-Debug 'This record does not exist yet, creating it'
        Write-Verbose "Creating record `"$RecordNameShort`" with value `"$TxtValue`" on domain `"$DomainName`""
        $queryParams = @{
            Uri = "https://$PorkbunAPIHost/api/json/v3/dns/create/$DomainName"
            Method = 'POST'
            BodyObject = @{
                name = $RecordNameShort
                type = 'TXT'
                content = $TxtValue
                apikey = $APIKey
                secretapikey = $APISecret
            }
        }
        try {
            $ResultData = Invoke-Porkbun @queryParams
            if ($ResultData.status -NE 'SUCCESS') { throw "API returned result $($ResultData.status)" }
            Write-Debug 'Successfully created record.'
        } catch {
            throw
        }
    }
    else
    {
        Write-Debug 'A record already exists with this value, so no creation is necessary'
        return
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Porkbun.
    .DESCRIPTION
        Adds or edits a DNS TXT record using Porkbun's API.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER PorkbunAPIKey
        The API key to use, obtained from https://porkbun.com/account/api
    .PARAMETER PorkbunSecret
        The API secret key corresponding to the API key, also obtained from https://porkbun.com/account/api (not accessible after being generated)
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Adds a TXT record for the specified site with the specified value. Does nothing if the record already exists.
    #>
}

function Remove-DnsTxt
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string] $RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string] $TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [SecureString] $PorkbunAPIKey,
        [Parameter(Mandatory, Position = 3)]
        [SecureString] $PorkbunSecret,
        [string] $PorkbunAPIHost = 'api.porkbun.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    [string] $APIKey = [PSCredential]::new('Username', $PorkbunAPIKey).GetNetworkCredential().Password
    [string] $APISecret = [PSCredential]::new('Username', $PorkbunSecret).GetNetworkCredential().Password

    $domainQuery = @{
        LongName = $RecordName
        PorkbunAPIKey = $APIKey
        PorkbunSecret = $APISecret
        PorkbunAPIHost = $PorkbunAPIHost
    }
    $DomainInfo = Get-PorkbunDomainInfo @domainQuery

    # Get the portion of the full name that is the domain name (e.g. 'record.name.sub.example.com' will become 'example.com')
    [string] $DomainName = $DomainInfo.Domain

    # Get any existing TXT record(s) that have matching content
    [object[]] $EqualRecords = @($DomainInfo.Records | Where-Object { ($_.type -EQ 'TXT') -AND ($_.name -eq $RecordName) -AND ($_.content -EQ $TxtValue) })

    if ($EqualRecords.Count -EQ 0)
    {
        Write-Debug 'There are no records with this content, so no deletion is necessary'
        return
    }
    else
    {
        Write-Debug "Found $($EqualRecords.Count) record(s) to delete."
        foreach($RecordToDelete in $EqualRecords)
        {
            $RecordID = $RecordToDelete.id

            Write-Verbose "Deleting record ID `"$RecordID`" on domain `"$DomainName`""
            $queryParams = @{
                Uri = "https://$PorkbunAPIHost/api/json/v3/dns/delete/$DomainName/$RecordID"
                Method = 'POST'
                BodyObject = @{
                    apikey = $APIKey
                    secretapikey = $APISecret
                }
            }
            try {
                $ResultData = Invoke-Porkbun @queryParams
                if ($ResultData.status -NE 'SUCCESS') { throw "API returned result $($ResultData.status)" }
                Write-Debug 'Successfully deleted record.'
            } catch {
                throw
            }
        }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Porkbun.
    .DESCRIPTION
        Removes a DNS TXT record using Porkbun's API.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER PorkbunAPIKey
        The API key to use, obtained from https://porkbun.com/account/api
    .PARAMETER PorkbunSecret
        The API secret key corresponding to the API key, also obtained from https://porkbun.com/account/api (not accessible after being generated)
    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Removes a TXT record for the specified site with the specified value. Does nothing if the record does not exist.
    #>
}

function Save-DnsTxt
{
    [CmdletBinding()]
    param
    (
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
    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications. (Not required)
    #>
}

##################################
# Helper Functions
##################################

# API Documentation: https://porkbun.com/api/json/v3/documentation

function Invoke-Porkbun
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [string]$Method,
        [hashtable]$BodyObject
    )

    # Porkbun seems to have some sort of rate limiting that results in HTTP 503 errors
    # when you hit it (or maybe it's just overloaded?). But there's no documentation
    # about it and there are no Retry-After headers in the response. So we're just
    # going to implement a dumb retry mechanic.
    $queryParams = @{
        Uri = $Uri
        Method = $Method
        Body = ($BodyObject | ConvertTo-Json)
        ErrorAction = 'Stop'
        Verbose = $false
    }

    # sanitize credentials for logging
    $BodyObject.apikey = 'REDACTED'
    $BodyObject.secretapikey = 'REDACTED'

    for ($i=0; $i -lt 3; $i++) {
        try {
            Write-Debug "POST $($queryParams.Uri)`n$($BodyObject|ConvertTo-Json)"
            $ResultData = Invoke-RestMethod @queryParams @script:UseBasic
            return $ResultData
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 503) {
                Write-Debug "API Temporarily Unavailable. Waiting and Re-trying."
                Start-Sleep -Seconds 2
                continue
            } else {
                throw
            }
        }
    }
    throw "API responding as Temporarily Unavailable. Gave up retrying."
}

function Get-PorkbunDomainInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string] $LongName,
        [Parameter(Mandatory)]
        [string] $PorkbunAPIKey,
        [Parameter(Mandatory)]
        [string] $PorkbunSecret,
        [string] $PorkbunAPIHost = 'api.porkbun.com'
    )

    Write-Debug "Looking for domain `"$LongName`""

    [string[]] $Sections = $LongName.Split('.')
    [int] $MaxIndex = $Sections.Count - 1
    for ([int]$i = 0; $i -lt $MaxIndex; $i++)
    {
        [string] $NameToCheck = [string]::Join('.', $Sections[$i .. $MaxIndex])
        Write-Debug "Querying API for `"$NameToCheck`""

        try {
            $queryParams = @{
                Uri = "https://$PorkbunAPIHost/api/json/v3/dns/retrieve/$NameToCheck"
                Method = 'POST'
                BodyObject = @{
                    apikey = $PorkbunAPIKey
                    secretapikey = $PorkbunSecret
                }
            }
            $ResultData = Invoke-Porkbun @queryParams
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 400) {
                Write-Debug "Could not find domain `"$NameToCheck`"."
                continue
            } else {
                Write-Debug "Something went wrong while checking domain `"$NameToCheck`""
                throw
            }
        }

        if ($ResultData.status -NE 'SUCCESS') {
            Write-Debug "API returned status $($ResultData.status) for domain `"$NameToCheck`""
            continue
        }

        Write-Debug "Found domain `"$NameToCheck`""
        $domainInfo = [pscustomobject]@{
            Domain = $NameToCheck
            Records = $ResultData.records
        }
        return $domainInfo
    }
    throw "No matching domain could be found for `"$LongName`" on this Porkbun account. Check that the domain is correct, that your API key and secret are entered correctly, and that you've enabled API access for this domain in the settings."

    <#
    .SYNOPSIS
        Finds the domain and existing records.
    .DESCRIPTION
        Uses the Porkbun API to find the relevant domain and existing records for this full name.
    .PARAMETER LongName
        The combined record/domain name to query for.
    .PARAMETER PorkbunAPIKey
        The API key to use, obtained from https://porkbun.com/account/api
    .PARAMETER PorkbunSecret
        The API secret key corresponding to the API key, also obtained from https://porkbun.com/account/api (not accessible after being generated)
    .OUTPUTS
        An object containing a 'Domain' property, which contains the base domain name, and a 'Records' property which contains all currently existing records for this domain, including ones for other subdomains.
    .EXAMPLE
        Get-PorkbunDomainInfo -PorkbunAPIKey (key) -PorkbunAPISecret (secret) -LongName 'long.name.for.example.com'
        Will return a Domain of 'example.com' and any records for that entire domain.
    #>
}
