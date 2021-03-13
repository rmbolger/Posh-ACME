function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZonomiApiKey,
        [string]$ZonomiApiUrl = 'https://zonomi.com/app/dns/dyndns.jsp',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $AuthHeader = @{"Authorization" = "redrata apikey=$ZonomiApiKey"}

    # Query existing TXT records
    $ApiParams = @{
        "action" = "QUERY";
        "name" = $RecordName;
        "type" = "TXT"
    }
    try {
        [xml]$XmlData = (Invoke-WebRequest $ZonomiApiUrl -Headers $AuthHeader -Body $ApiParams `
            @script:UseBasic).Content
    } catch { throw }


    # Add any existing TXT records to the API command
    $ApiParams.Clear()
    $i = 1
    $XmlData.SelectNodes("//record/@content") | ForEach-Object {
        $ApiParams.Add("action[$i]", "SET")
        $ApiParams.Add("name[$i]", $RecordName)
        $ApiParams.Add("value[$i]", $_.Value)
        $ApiParams.Add("type[$i]", "TXT")
        $i++
    }

    # Add the new TXT record to the API command
    $ApiParams.Add("action[$i]", "SET")
    $ApiParams.Add("name[$i]", $RecordName)
    $ApiParams.Add("value[$i]", $TxtValue)
    $ApiParams.Add("type[$i]", "TXT")

    # Run the API command
    Invoke-WebRequest $ZonomiApiUrl -Headers $AuthHeader -Body $ApiParams @Script:UseBasic | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record to Zonomi.

    .DESCRIPTION
        Uses the Zonomi DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZonomiApiKey
        Your Zonomi DNS API key.

    .PARAMETER ZonomiApiUrl
        The base URL for the API.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key'

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
        [Parameter(Mandatory,Position=2)]
        [string]$ZonomiApiKey,
        [string]$ZonomiApiUrl = 'https://zonomi.com/app/dns/dyndns.jsp',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $AuthHeader = @{"Authorization" = "redrata apikey=$ZonomiApiKey"}

	# Add the TXT record to the API command
	$ApiParams = @{
        "action" = "DELETE";
        "name" = $RecordName;
        "value" = $TxtValue;
        "type" = "TXT"
    }

    # Run the API command
    Invoke-WebRequest $ZonomiApiUrl -Headers $AuthHeader -Body $ApiParams @Script:UseBasic | Out-Null

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Zonomi.

    .DESCRIPTION
        Uses the Zonomi DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZonomiApiKey
        Your Zonomi DNS API key.

    .PARAMETER ZonomiApiUrl
        The base URL for the API.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key'

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
