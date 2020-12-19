function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DuckToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$DuckTokenInsecure,
        [Parameter(Mandatory,Position=3)]
        [string[]]$DuckDomain,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DuckTokenInsecure = [pscredential]::new('a',$DuckToken).GetNetworkCredential().Password
    }

    Write-Verbose "Adding TXT $TxtValue on DuckDNS for $($DuckDomain -join ',')"
    $domains = $DuckDomain -join ','
    $uri = "https://www.duckdns.org/update?domains=$domains&token=$DuckTokenInsecure&txt=$TxtValue&verbose=true"
    try {
        Write-Debug "GET $($uri.Replace($DuckTokenInsecure,'REDACTED'))"
        $response = Invoke-RestMethod $uri @script:UseBasic -Verbose:$false -EA Stop
        Write-Debug "Response:`n$response"
    } catch { throw }

    if ($response -notlike 'OK*') {
        throw "Failed to add DuckDNS TXT record.`n$response"
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
        The API token for DuckDNS.

    .PARAMETER DuckTokenInsecure
        (DEPRECATED) The API token for DuckDNS.

    .PARAMETER DuckDomains
        The list of domains associated with this token to update. Domains do not need to include the .duckdns.org part, just the subname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.mydomain.duckdns.org' 'txt-value' $token 'mydomain'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DuckToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$DuckTokenInsecure,
        [Parameter(Mandatory,Position=3)]
        [string[]]$DuckDomain,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DuckTokenInsecure = [pscredential]::new('a',$DuckToken).GetNetworkCredential().Password
    }

    Write-Verbose "Clearing TXT on DuckDNS for $($DuckDomain -join ',')"
    $domains = $DuckDomain -join ','
    $uri = "https://www.duckdns.org/update?domains=$domains&token=$DuckTokenInsecure&txt=$TxtValue&clear=true&verbose=true"
    try {
        Write-Debug "GET $($uri.Replace($DuckTokenInsecure,'REDACTED'))"
        $response = Invoke-RestMethod $uri @script:UseBasic -Verbose:$false -EA Stop
        Write-Debug "Response:`n$response"
    } catch { throw }

    if ($response -notlike 'OK*') {
        throw "Failed to clear DuckDNS TXT record.`n$response"
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
        The API token for DuckDNS.

    .PARAMETER DuckTokenInsecure
        (DEPRECATED) The API token for DuckDNS.

    .PARAMETER DuckDomains
        The list of domains associated with this token to update. Domains do not need to include the .duckdns.org part, just the subname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.mydomain.duckdns.org' 'txt-value' $token 'mydomain'

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
