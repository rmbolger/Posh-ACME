function Add-DnsTxtDomainOffensive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Token,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue
    )

    Write-Verbose "Adding $RecordName with value $TxtValue on Domain Offensive"
    $uri = "https://www.do.de/api/letsencrypt?token=$Token&domain=$RecordName&value=$TxtValue"
    $response = Invoke-RestMethod -Method Get -Uri $uri @script:UseBasic
    
    if (!$response.success) {
        throw "Failed to add Domain Offensive DNS record; Result=$($response)"
    }
    
    <#
    .SYNOPSIS
        Add a DNS TXT record to a Domain Offensive DNS Zone

    .DESCRIPTION
        Add a DNS TXT record to a Domain Offensive DNS Zone

    .PARAMETER Token
        Token provided by Domain Offensive.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .EXAMPLE
        Add-DnsTxtDomainOffensive '1md6xRcUCTrB58kbpwAH' '_acme-challenge.site1.example.com' 'OVxwaDm7MgN1IRG0eSivJMlepO9CL4X8vKo6Tcns'

        Adds a TXT record for the specified site with the specified value using the account associated with the given token.

    .LINK
        https://www.do.de/wiki/LetsEncrypt_-_Entwickler
    #>
}

function Remove-DnsTxtDomainOffensive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Token,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordName
    )

    Write-Verbose "Removing $RecordName with value $TxtValue on Domain Offensive"
    $uri = "https://www.do.de/api/letsencrypt?token=$Token&domain=$RecordName&action=delete"
    $response = Invoke-RestMethod -Method Get -Uri $uri @script:UseBasic
    
    if (!$response.success) {
        throw "Failed to remove Domain Offensive DNS record; Result=$($response)"
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Domain Offensive DNS

    .DESCRIPTION
        Remove a DNS TXT record from Domain Offensive DNS

    .PARAMETER Token
        Token provided by Domain Offensive.

    .PARAMETER Domain
        The fully qualified name of the TXT record to be removed.

    .EXAMPLE
        Add-DnsTxtDomainOffensive '1md6xRcUCTrB58kbpwAH' '_acme-challenge.site1.example.com'

        Adds a TXT record for the specified site with the specified value using the account associated with the given token.

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
