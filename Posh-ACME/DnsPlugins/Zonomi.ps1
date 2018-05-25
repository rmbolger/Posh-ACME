function Add-DnsTxtZonomi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZonomiApiKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $ApiUri = "https://zonomi.com/app/dns/dyndns.jsp"
    $AuthHeader = @{"Authorization" = "redrata apikey=$ZonomiApiKey"}

    # Query existing TXT records
    $ApiParams = @{
        "action" = "QUERY";
        "name" = $RecordName;
        "type" = "TXT"
    }
    try {
        [xml]$XmlData = (Invoke-WebRequest $ApiUri -Headers $AuthHeader -Body $ApiParams `
            @script:UseBasic).Content
    } catch { throw }


    # Add any existing TXT records to the API command
    $ApiParams.Clear()
    $XmlData.SelectNodes("//record/@content") | % {$i=1} {
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
    Invoke-WebRequest $ApiUri -Headers $AuthHeader -Body $ApiParams @Script:UseBasic | Out-Null

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

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'abcdefghijklmnopqrstuvwxyz'

        Adds a TXT record for the specified site with the specified value.
    #>
}


function Remove-DnsTxtZonomi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZonomiApiKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $ApiUri = "https://zonomi.com/app/dns/dyndns.jsp"
    $AuthHeader = @{"Authorization" = "redrata apikey=$ZonomiApiKey"}

	# Add the TXT record to the API command
	$ApiParams = @{
        "action" = "DELETE";
        "name" = $RecordName;
        "value" = $TxtValue;
        "type" = "TXT"
    }

    # Run the API command
    Invoke-WebRequest $ApiUri -Headers $AuthHeader -Body $ApiParams @Script:UseBasic | Out-Null

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

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'abcdefghijklmnopqrstuvwxyz'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtZonomi {
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
