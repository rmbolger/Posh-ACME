function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$NameSiloKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$NameSiloKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $NameSiloKeyInsecure = (New-Object pscredential "user",$NameSiloKey).GetNetworkCredential().Password
    }

    # query the zone and record ID if it exists
    $zone, $recID = Get-NameSiloTXTRecordID $RecordName $TxtValue $NameSiloKeyInsecure

    if ($recID) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {

        $recShort = ($RecordName -ireplace [regex]::Escape($zone), [string]::Empty).TrimEnd('.')

        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        try {
            $query = "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=$($NameSiloKeyInsecure)&domain=$($zone)&rrtype=TXT&rrhost=$($recShort)&rrvalue=$($TxtValue)&rrttl=3600"
            $response = Invoke-RestMethod $query @script:UseBasic -EA Stop
        } catch { throw }

        if ($response -and $response.namesilo.reply.code -ne 300) {
            throw "Failed to add TXT record: $($response.namesilo.reply.detail)"
        }

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

    .PARAMETER NameSiloKey
        The API key for the NameSilo account. Created at https://www.namesilo.com/account/api-manager. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER NameSiloKeyInsecure
        The API key for the NameSilo account. Created at https://www.namesilo.com/account/api-manager. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt -RecordName '_acme-challenge.example.com' 'txt-value' -NameSiloKeyInsecure 'api-key'

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
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$NameSiloKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$NameSiloKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $NameSiloKeyInsecure = (New-Object pscredential "user",$NameSiloKey).GetNetworkCredential().Password
    }

    # query the zone and record ID if it exists
    $zone, $recID = Get-NameSiloTXTRecordID $RecordName $TxtValue $NameSiloKeyInsecure

    if ($recID) {

        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue and id $recID"

        $query = "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=xml&key=$($NameSiloKeyInsecure)&domain=$($zone)&rrid=$($recID)"
        $response = Invoke-RestMethod $query @script:UseBasic -EA Stop
        if ($response -and $response.namesilo.reply.code -ne 300) {
            throw "Failed to delete record: $($response.namesilo.reply.detail)"
        }

    } else {
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

    .PARAMETER NameSiloKey
        The API key for the NameSilo account. Created at https://www.namesilo.com/account/api-manager. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER NameSiloKeyInsecure
        The API key for the NameSilo account. Created at https://www.namesilo.com/account/api-manager. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt -RecordName '_acme-challenge.example.com' 'txt-value' -NameSiloKeyInsecure 'api-key'

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
        Not required

    .DESCRIPTION
        This provider does not require calling this function to save DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}


##################################
# Helper Functions
##################################

# https://www.namesilo.com/api-reference

function Get-NameSiloTXTRecordID {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NameSiloKeyInsecure
    )

    # Get the zone from the record name
    $zone = Find-NameSiloZone $RecordName $NameSiloKeyInsecure
    if ($null -eq $zone) {
        throw "Cannot find NameSilo domain for $RecordName"
    }

    # query all records for the zone
    try {
        $query = "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$($NameSiloKeyInsecure)&domain=$($zone)"
        $response = Invoke-RestMethod $query @script:UseBasic -EA Stop
    } catch { throw }
    if ($response -and $response.namesilo.reply.code -ne 300) {
        throw "Failed to list domain records: $($response.namesilo.reply.detail)"
    }

    # grab the matching record if it exists
    $record = $response.namesilo.reply.resource_record | Where-Object {
        $_.type -eq 'TXT' -and
        $_.host -eq $RecordName -and
        $_.value -eq $TxtValue
    }

    # return the record ID and zone name
    if ($record) {
        return @($zone,$record.record_id)
    } else {
        return @($zone,$null)
    }

}

function Find-NameSiloZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$NameSiloKeyInsecure
    )

    if (!$script:NameSiloZones) { $script:NameSiloZones = @{} }

    if ($script:NameSiloZones.ContainsKey($RecordName)) {
        return $script:NameSiloZones.$RecordName
    }

    # grab the list of registered domains for this account
    $query = "https://www.namesilo.com/api/listDomains?version=1&type=xml&key=$($NameSiloKeyInsecure)"
    $response = Invoke-RestMethod $query @script:UseBasic -EA Stop
    if ($response -and $response.namesilo.reply.code -ne 300) {
        throw "Unexpected response from NameSilo API: $($response.namesilo.reply.detail)"
    }
    $domains = @($response.namesilo.reply.domains.domain)

    # find the closest match based on the record name
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zone = $pieces[$i..($pieces.Count-1)] -join '.'

        if ($zone -in $domains) {
            $script:NameSiloZones.$RecordName = $zone
            return $zone
        }
    }

    return $null
}
