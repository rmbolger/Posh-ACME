function Add-DnsTxtAcmeDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [pscredential]$ACMECred,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # create the credential header object
    $credHead = @{'X-Api-User'=$ACMECred.UserName;'X-Api-Key'=($ACMECred.GetNetworkCredential().Password)}

    # RecordName can be split into the root acme-dns domain and the subdomain that we're updating
    $subdomain = $RecordName.Substring(0,$RecordName.IndexOf('.'))
    $apiRoot = "https://$($RecordName.Substring($RecordName.IndexOf('.')+1))/update"

    # create the update body
    $updateBody = @{subdomain=$subdomain;txt=$TxtValue} | ConvertTo-Json -Compress

    # send the update
    Invoke-RestMethod $apiRoot -Method Post -Headers $credHead -Body $updateBody | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record to acme-dns

    .DESCRIPTION
        This plugin requires using the -DnsAlias option. The value for DnsAlias is the "fulldomain" returned by the acme-dns register endpoint.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ACMECred
        The username and password in the object returned by the register endpoint on acme-dns.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtAcmeDns '_acme-challenge.site1.example.com' 'xxxxxxxxxxXXXXXXXXXXxxxxxxxxxxXXXXXXXXXX001' 'f48d6f87-77bf-4b86-9a51-d1aa82eab427.auth.acme-dns.io' (Get-Credential)

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtAcmeDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. acme-dns doesn't have a remove method

    <#
    .SYNOPSIS
        Not required for acme-dns.

    .DESCRIPTION
        acme-dns does not have a remove method. So this function does nothing.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtAcmeDns '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtAcmeDns {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. acme-dns doesn't have a remove method

    <#
    .SYNOPSIS
        Not required for acme-dns.

    .DESCRIPTION
        acme-dns does not have a save method. So this function does nothing.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
