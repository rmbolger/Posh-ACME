function Add-DnsTxtDreamhost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DreamhostApiKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Adding $RecordName with value $TxtValue on Dreamhost"
    $uri = "https://api.dreamhost.com/?cmd=dns-add_record&type=TXT&format=json&key=$DreamhostApiKey&record=$RecordName&value=$TxtValue"
    $response = Invoke-RestMethod -Method Get -Uri $uri @script:UseBasic
    Write-Verbose "Result=$($response.result), Data=$($response.data)"
    
    if ($response.result -ne 'success' -and !([string]$response.data).StartsWith('record_already_exists')) {
        throw "Failed to add Dreamhost DNS record; Result=$($response.result), Data=$($response.data)"
    }
    
    <#
    .SYNOPSIS
        Add a DNS TXT record to Dreamhost DNS

    .DESCRIPTION
        Add a DNS TXT record to Dreamhost DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ApiKey
        A Dreamhost API key with minimum function access of dns-add_record and dns-remove_record. See related links for URI to Dreamhost panel for API key generation.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtDreamhost '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'ABCDEFGH12345678'

        Adds a TXT record for the specified site with the specified value using the default account associated with the given API key.

    .LINK
        https://panel.dreamhost.com/?tree=home.api
    #>
}

function Remove-DnsTxtDreamhost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DreamhostApiKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Removing $RecordName with value $TxtValue on Dreamhost"
    $uri = "https://api.dreamhost.com/?cmd=dns-remove_record&type=TXT&format=json&key=$DreamhostApiKey&record=$RecordName&value=$TxtValue"
    $response = Invoke-RestMethod -Method Get -Uri $uri @script:UseBasic
    Write-Verbose "Result=$($response.result), Data=$($response.data)"
    
    if ($response.result -ne 'success' -and !([string]$response.data).StartsWith('no_such_')) {
        throw "Failed to remove Dreamhost DNS record; Result=$($response.result), Data=$($response.data)"
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Dreamhost DNS

    .DESCRIPTION
        Remove a DNS TXT record from Dreamhost DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ApiKey
        A Dreamhost API key with minimum function access of dns-add_record and dns-remove_record. See related links for URI to Dreamhost panel for API key generation.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtDreamhost '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'ABCDEFGH12345678'

        Removes a TXT record for the specified site with the specified value using the default account associated with the given API key.
    #>
}

function Save-DnsTxtDreamhost {
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