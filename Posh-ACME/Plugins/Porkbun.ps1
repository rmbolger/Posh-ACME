using namespace Systen;
using namespace Microsoft.PowerShell.Commands;

# API Documentation: https://porkbun.com/api/json/v3/documentation

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
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    );

    [string] $APIKey = [PSCredential]::new('Username', $PorkbunAPIKey).GetNetworkCredential().Password;
    [string] $APISecret = [PSCredential]::new('Username', $PorkbunSecret).GetNetworkCredential().Password;

    $DomainInfo = Get-PorkbunDomainInfo -PorkbunAPIKey $APIKey -PorkbunSecret $APISecret -LongName $RecordName;

    # Get the portion of the full name that is the domain name (e.g. 'record.name.sub.example.com' will become 'example.com')
    [string] $DomainName = $DomainInfo.Domain;
    # Get the portion of the full name that will become the record name (e.g. 'record.name.sub.example.com' will become 'record.name.sub')
    [string] $RecordNameShort = ($RecordName -ireplace [Regex]::Escape($DomainName), [string]::Empty).TrimEnd('.');

    # Get any existing TXT record(s) that already match what we want to create
    [object[]] $EqualRecords = @($DomainInfo.Records | Where-Object { ($_.type -EQ 'TXT') -AND ($_.name -eq $RecordNameShort) -AND ($_.content -EQ $TxtValue) });

    if ($EqualRecords.Count -EQ 0)
    {
        Write-Debug 'This record does not exist yet, creating it';
        [string] $RequestBody = "{`"secretapikey`": `"$APISecret`", `"apikey`": `"$APIKey`", `"name`": `"$RecordNameShort`", `"type`": `"TXT`", `"content`": `"$TxtValue`"}";
        [string] $RequestURL = "https://porkbun.com/api/json/v3/dns/create/$DomainName";

        Write-Debug "Creating record `"$RecordNameShort`" on domain `"$DomainName`"";
        [BasicHtmlWebResponseObject] $APIResult = Invoke-WebRequest -URI $RequestURL -Body $RequestBody -Method 'POST' @script:UseBasic;
        if ($APIResult.StatusCode -NE 200) { throw "API returned status $($APIResult.StatusCode)"; }
        $ResultData = ConvertFrom-Json $APIResult.Content;
        if ($ResultData.status -NE 'SUCCESS') { throw "API returned result $($ResultData.status)"; }
        Write-Debug 'Successfully created record.';
    }
    else
    {
        Write-Debug 'A record already exists with this value, so no creation is necessary';
        return;
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
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    );

    [string] $APIKey = [PSCredential]::new('Username', $PorkbunAPIKey).GetNetworkCredential().Password;
    [string] $APISecret = [PSCredential]::new('Username', $PorkbunSecret).GetNetworkCredential().Password;

    $DomainInfo = Get-PorkbunDomainInfo -PorkbunAPIKey $APIKey -PorkbunSecret $APISecret -LongName $RecordName;

    # Get the portion of the full name that is the domain name (e.g. 'record.name.sub.example.com' will become 'example.com')
    [string] $DomainName = $DomainInfo.Domain;

    # Get any existing TXT record(s) that have matching content
    [object[]] $EqualRecords = @($DomainInfo.Records | Where-Object { ($_.type -EQ 'TXT') -AND ($_.name -eq $RecordName) -AND ($_.content -EQ $TxtValue) });

    if ($EqualRecords.Count -EQ 0)
    {
        Write-Debug 'There are no records with this content, so no deletion is necessary';
        return;
    }
    else
    {
        Write-Debug "Found $($EqualRecords.Count) record(s) to delete.";
        foreach($RecordToDelete in $EqualRecords)
        {
            $RecordID = $RecordToDelete.id;
            [string] $RequestBody = "{`"secretapikey`": `"$APISecret`", `"apikey`": `"$APIKey`"}";
            [string] $RequestURL = "https://porkbun.com/api/json/v3/dns/delete/$DomainName/$RecordID";

            Write-Debug "Deleting record ID `"$RecordID`" on domain `"$DomainName`"";
            [BasicHtmlWebResponseObject] $APIResult = Invoke-WebRequest -URI $RequestURL -Body $RequestBody -Method 'POST' @script:UseBasic;
            if ($APIResult.StatusCode -NE 200) { throw "API returned status $($APIResult.StatusCode)"; }
            $ResultData = ConvertFrom-Json $APIResult.Content;
            if ($ResultData.status -NE 'SUCCESS') { throw "API returned result $($ResultData.status)"; }
            Write-Debug 'Successfully deleted record.';
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
    );

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

function Get-PorkbunDomainInfo
{
    param
    (
        [string] $PorkbunAPIKey,
        [string] $PorkbunSecret,
        [string] $LongName
    );

    [string] $RequestBody = "{`"secretapikey`": `"$PorkbunSecret`", `"apikey`": `"$PorkbunAPIKey`"}";

    Write-Debug "Looking for domain `"$LongName`"";
    [string[]] $Sections = $LongName.Split('.');
    [int] $MaxIndex = $Sections.Count - 1;
    for ([int]$i = 0; $i -LT $MaxIndex; $i++)
    {
        [string] $NameToCheck = [string]::Join('.', $Sections[$i .. $MaxIndex]);
        [string] $RequestURL = "https://porkbun.com/api/json/v3/dns/retrieve/$NameToCheck";
        Write-Debug "Querying API for `"$NameToCheck`"";

        try { [BasicHtmlWebResponseObject] $APIResult = Invoke-WebRequest -URI $RequestURL -Body $RequestBody -Method 'POST' @script:UseBasic; }
        catch [InvalidOperationException] { Write-Debug "Could not find domain `"$NameToCheck`"."; continue; }
        catch { Write-Debug "Something went wrong while checking domain `"$NameToCheck`""; throw; }

        if ($APIResult.StatusCode -NE 200) { Write-Debug "API returned code $($APIResult.StatusCode) for domain `"$NameToCheck`""; continue; }
        $ResultData = ConvertFrom-Json $APIResult.Content;
        if ($ResultData.status -NE 'SUCCESS') { Write-Debug "API returned status $($ResultData.status) for domain `"$NameToCheck`""; continue; }

        Write-Debug "Found domain `"$NameToCheck`"";
        return New-Object 'PSObject' -Property @{ Domain = $NameToCheck; Records = $ResultData.records; };
    }
    throw "No matching domain could be found for `"$LongName`" on this Porkbun account. Check that the domain is correct, that your API key and secret are entered correctly, and that you've enabled API access for this domain in the settings.";

    <#
    .SYNOPSIS
        Finds the domain and existing records.
    .DESCRIPTION
        Uses the Porkbun API to find the relevant domain and existing records for this full name.
    .PARAMETER PorkbunAPIKey
        The API key to use, obtained from https://porkbun.com/account/api
    .PARAMETER PorkbunSecret
        The API secret key corresponding to the API key, also obtained from https://porkbun.com/account/api (not accessible after being generated)
    .PARAMETER LongName
        The combined record/domain name to query for.
    .OUTPUTS
        An object containing a 'Domain' property, which contains the base domain name, and a 'Records' property which contains all currently existing records for this domain, including ones for other subdomains.
    .EXAMPLE
        Get-PorkbunDomainInfo -PorkbunAPIKey (key) -PorkbunAPISecret (secret) -LongName 'long.name.for.example.com'
        Will return a Domain of 'example.com' and any records for that entire domain.
    #>
}