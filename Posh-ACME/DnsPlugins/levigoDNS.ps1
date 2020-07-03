function Add-DnsTxtLevigoDNS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$levigoDNSuser,
        [Parameter(Mandatory,Position=3)]
        [string]$levigoDNSpassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
 
    Write-Verbose "Adding $RecordName with value $TxtValue"
    # build json string
    $json = @{ username=$levigoDNSuser; password=$levigoDNSpassword; recordtype="TXT"; rrdatas=$TxtValue } | ConvertTo-Json
    # add the new TXT record
    Invoke-RestMethod "https://acme.levigo.net/v1/zones/$RecordName/dns_records" -Method Put -Body $json -ContentType 'application/json' | Out-Null
 
    <#
    .SYNOPSIS
        Add a DNS TXT record to levigoDNS.
    .DESCRIPTION
        Uses levigoDNS v1 API to add a TXT record to a levigoDNS managed zone.
    .PARAMETER RecordName
        The FQDN of the TXT record.
    .PARAMETER TxtValue
        The content of the TXT record.
    .PARAMETER levigoDNSuser
        The username of the account used to connect to levigoDNS REST-API
    .PARAMETER levigoDNSpassword
        The password of the account associated with levigoDNSuser parameter.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxtLevigoDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'username' 'password'
        Adds a TXT record with the specified TxtValue to the RecordName.
    #>
}
 
function Remove-DnsTxtLevigoDNS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$levigoDNSuser,
        [Parameter(Mandatory,Position=3)]
        [string]$levigoDNSpassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
 
    Write-Verbose "Removing $RecordName with value $TxtValue"
    # build json string
    $json = @{ username=$levigoDNSuser; password=$levigoDNSpassword; recordtype="TXT"; rrdatas=$TxtValue } | ConvertTo-Json
    # remove the new TXT record
    Invoke-RestMethod "https://acme.levigo.net/v1/zones/$RecordName/dns_records" -Method Delete -Body $json -ContentType 'application/json' | Out-Null
 
    <#
    .SYNOPSIS
        Remove a DNS TXT record from levigoDNS.
    .DESCRIPTION
        Use levigoDNS v1 API to remove a TXT record from a levigoDNS managed zone.
    .PARAMETER RecordName
        The FQDN of the TXT record.
    .PARAMETER TxtValue
        The content of the TXT record.
    .PARAMETER levigoDNSuser
        The username of the account used to connect to levigoDNS REST-API.
    .PARAMETER levigoDNSpassword
        The password of the account associated with levigoDNSuser parameter.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxtLevigoDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'username' 'password'
        Removes a TXT record with the specified TxtValue from the specified RecordName.
    #>
}
 
function Save-DnsTxtLevigoDNS {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required.
    .DESCRIPTION
        levigoDNS REST-API does not require calling this function to commit changes to DNS records.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}