function Add-DnsTxtNameSilo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,        
        [Parameter(Mandatory,Position=2)]
        [string]$NameSiloApiKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiBase = 'https://www.namesilo.com/api'
    $RecordName = $RecordName.ToLower()
    $domainList = $RecordName.Split('.')
    $domainCount = @($domainList).Count - 1
    $Domain = $domainList[$domainCount-1] + "." + $domainList[$domainCount]
    $RecordName = $RecordName.TrimEnd($Domain)
    try {       
        $uri = "$apiBase/dnsAddRecord?version=1&type=xml&key=$($NameSiloApiKey)&domain=$($Domain)&rrtype=TXT&rrhost=$($RecordName)&rrvalue=$($TxtValue)&rrttl=3600"
        $response = Invoke-RestMethod -Uri $uri @script:UseBasic
    } catch { throw }

    if ($response["namesilo"].reply.code -cne 300) {
        throw "Failed to add TXT record: $($response["namesilo"].reply.detail)"
    }
    

    <#
    .SYNOPSIS
        Add a DNS TXT record to NameSilo

    .DESCRIPTION
        Adds the TXT record to the NameSilo Zone

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NameSiloApiKey
        The API key for the NameSilo account. Created at https://www.namesilo.com/account/api-manager

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtNameSilo -RecordName "_acme-challenge.site1.example.com" -TxtValue "asdfqwer12345678" -Domain "example.com" -NameSiloApiKey "namesilo_api_key"

        Adds a TXT record for the specified domain with the specified value.
    #>
}

function Remove-DnsTxtNameSilo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NameSiloApiKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiBase = 'https://www.namesilo.com/api'
    $RecordName = $RecordName.ToLower()
    $domainList = $RecordName.Split('.')
    $domainCount = @($domainList).Count - 1
    $Domain = $domainList[$domainCount-1] + "." + $domainList[$domainCount]
    $RecordName = $RecordName.TrimEnd($Domain)
    try {
        $response = Invoke-RestMethod "$apiBase/dnsListRecords?version=1&type=xml&key=$($NameSiloApiKey)&domain=$($Domain)" @script:UseBasic
    } catch { throw }

    $reply = $response["namesilo"].reply

    if ($reply.code -cne 300) {
        throw "Failed to list domain records: $($reply.detail)"
    }
    
    $record = $reply.resource_record | Where-Object {$_.type -match "TXT" -and $_.host -match $($RecordName) -and $_.value -match $($TxtValue)}
    if (@($record).Count -eq 1) {
        # grab the record and delete it
        try {
            Write-Verbose "Deleting $RecordName with value $TxtValue"
            $rrid = $record.record_id
            $response2 = Invoke-RestMethod "$apiBase/dnsDeleteRecord?version=1&type=xml&key=$($NameSiloApiKey)&domain=$($Domain)&rrid=$($rrid)" @script:UseBasic
            $reply2 = $response2["namesilo"].reply
            if ($reply2.code -cne 300) {
                throw "Failed to list domain records: $($reply2.detail)"
            }    
        } catch { throw }
    } elseif (@($record).Count -gt 1) {
        throw "multiple domain records found"
    }
    else {
        # nothing to do
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from NameSilo

    .DESCRIPTION
        Removes the TXT record from the NameSilo zone

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NameSiloApiKey
        The API key for the NameSilo account. Created at https://www.namesilo.com/api-reference

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtNameSilo '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'NameSilo_api_client_id' 'NameSilo_api_client_secret'

        Removes a TXT record for the specified domain with the specified value.
    #>
}

function Save-DnsTxtNameSilo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required

    .DESCRIPTION
        This provider does not require calling this function to save DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
