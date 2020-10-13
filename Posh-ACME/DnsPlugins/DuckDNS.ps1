function Add-DnsTxtDuckDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DuckToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$DuckTokenInsecure,
        [Parameter(Mandatory,Position=3)]
        [string[]]$DuckDomain,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DuckTokenInsecure = (New-Object PSCredential "user",$DuckToken).GetNetworkCredential().Password
    }

    Write-Verbose "Adding TXT $TxtValue on DuckDNS for $($DuckDomain -join ',')"
    $domains = $DuckDomain -join ','
    $uri = "https://www.duckdns.org/update?domains=$domains&token=$DuckTokenInsecure&txt=$TxtValue"
    try {
        $response = Invoke-RestMethod $uri @script:UseBasic -EA Stop
    } catch { throw }

    if ($response -ne 'OK') {
        throw "Failed to add DuckDNS TXT record."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to DuckDNS

    .DESCRIPTION
        Add a DNS TXT record to DuckDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DuckToken
        The API token for DuckDNS. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DuckTokenInsecure
        The API token for DuckDNS. This standard String version may be used on any OS.

    .PARAMETER DuckDomains
        The list of domains associated with this token to update. Domains do not need to include the .duckdns.org part, just the subname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtDuckDNS '_acme-challenge.mydomain.duckdns.org' 'txt-value' 'token-value' 'mydomain'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtDuckDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DuckToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$DuckTokenInsecure,
        [Parameter(Mandatory,Position=3)]
        [string[]]$DuckDomain,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DuckTokenInsecure = (New-Object PSCredential "user",$DuckToken).GetNetworkCredential().Password
    }

    Write-Verbose "Clearing TXT on DuckDNS for $($DuckDomain -join ',')"
    $domains = $DuckDomain -join ','
    $uri = "https://www.duckdns.org/update?domains=$domains&token=$DuckTokenInsecure&txt=$TxtValue&clear=true"
    try {
        $response = Invoke-RestMethod $uri @script:UseBasic -EA Stop
    } catch { throw }

    if ($response -ne 'OK') {
        throw "Failed to clear DuckDNS TXT record."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from DuckDNS

    .DESCRIPTION
        Remove a DNS TXT record from DuckDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DuckToken
        The API token for DuckDNS. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DuckTokenInsecure
        The API token for DuckDNS. This standard String version may be used on any OS.

    .PARAMETER DuckDomains
        The list of domains associated with this token to update. Domains do not need to include the .duckdns.org part, just the subname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtDuckDNS '_acme-challenge.mydomain.duckdns.org' 'txt-value' 'token-value' 'mydomain'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtDuckDNS {
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
