function Add-DnsTxtDomainOffensive {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure', Mandatory, Position=2)]
        [securestring]$DomOffToken,
        [Parameter(ParameterSetName='Insecure', Mandatory, Position=2)]
        [string]$DomOffTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Decrypt the secure string token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DomOffTokenInsecure = (New-Object PSCredential "user", $DomOffToken).GetNetworkCredential().Password
    }

    Write-Verbose "Adding $RecordName with value $TxtValue on Domain Offensive"
    $uri = "https://www.do.de/api/letsencrypt?token=$DomOffTokenInsecure&domain=$RecordName&value=$TxtValue"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri @script:UseBasic -EA Stop
    } catch { throw }

    if (!$response.success) {
        throw "Failed to add Domain Offensive DNS record; Result=$($response)"
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to a Domain Offensive DNS Zone

    .DESCRIPTION
        Add a DNS TXT record to a Domain Offensive DNS Zone

    .PARAMETER DomOffToken
        Token as provided by Domain Offensive. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DomOffTokenInsecure
        Token as provided by Domain Offensive. Works on any OS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .EXAMPLE
        $secToken = Read-Host -Prompt "Token" -AsSecureString
        PS C:\>Add-DnsTxtDomainOffensive '_acme-challenge.example.com' 'txt-value' $secToken

        Adds the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Add-DnsTxtDomainOffensive '_acme-challenge.example.com' 'txt-value' 'token-value'

        Adds the specified TXT record with the specified value using a standard string token.

    .LINK
        https://www.do.de/wiki/LetsEncrypt_-_Entwickler
    #>
}

function Remove-DnsTxtDomainOffensive {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure', Mandatory, Position=2)]
        [securestring]$DomOffToken,
        [Parameter(ParameterSetName='Insecure', Mandatory, Position=2)]
        [string]$DomOffTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Decrypt the secure string token
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DomOffTokenInsecure = (New-Object PSCredential "user", $DomOffToken).GetNetworkCredential().Password
    }

    Write-Verbose "Removing $RecordName with value $TxtValue on Domain Offensive"
    $uri = "https://www.do.de/api/letsencrypt?token=$DomOffTokenInsecure&domain=$RecordName&action=delete"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri @script:UseBasic -EA Stop
    } catch { throw }

    if (!$response.success) {
        throw "Failed to remove Domain Offensive DNS record; Result=$($response)"
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Domain Offensive DNS

    .DESCRIPTION
        Remove a DNS TXT record from Domain Offensive DNS

    .PARAMETER DomOffToken
        Token as provided by Domain Offensive. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DomOffTokenInsecure
        Token as provided by Domain Offensive. Works on any OS.

    .PARAMETER Domain
        The fully qualified name of the TXT record to be removed.

    .EXAMPLE
        $secToken = Read-Host -Prompt "Token" -AsSecureString
        PS C:\>Remove-DnsTxtDomainOffensive '_acme-challenge.example.com' 'txt-value' $secToken

        Removes the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Remove-DnsTxtDomainOffensive '_acme-challenge.example.com' 'txt-value' 'token-value'

        Removes the specified TXT record with the specified value using a standard string token.

    .LINK
        https://www.do.de/wiki/LetsEncrypt_-_Entwickler
    #>
}

function Save-DnsTxtDomainOffensive {
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
