function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$HECredential,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$HEUsername,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$HEPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # add the new record
    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

    # get plain text versions of the pscredential we can work with
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HEUsername = $HECredential.UserName
        $HEPassword = $HECredential.GetNetworkCredential().Password
    }

    # URI escape the credentials
    $userEscaped = [uri]::EscapeDataString($HEUsername)
    $passEscaped = [uri]::EscapeDataString($HEPassword)

    # build the form body
    $addBody = "hostname=$userEscaped&password=$passEscaped&txt=$TxtValue"
    $iwrArgs = @{
        Uri = 'https://dyn.dns.he.net/nic/update'
        Method = 'Post'
        Body = $addBody
        ErrorAction = 'Stop'
    }

    try {
        $response = Invoke-WebRequest @iwrArgs @script:UseBasic
    } catch { throw }

    $reStatus = '^(nochg|good)'

    if (-Not($response.Content -match $reStatus)) {
        Write-Warning "Unexpected result status while adding record: $($response.Content)"
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hurricane Electric using their Dynamic TXT API.

    .DESCRIPTION
        Add a DNS TXT record to Hurricane Electric using their Dynamic TXT API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HECredential
        Username and password for Hurricane Electric using their Dynamic TXT API. 

        The username should match the hostname being used to ultimately store the challenge. The password should match the password set
        in the user interface for the hostname.

    .PARAMETER HEUsername
        (DEPRECATED) Username for Hurricane Electric using their Dynamic TXT API.

        The username should match the hostname being used to ultimately store the challenge.

    .PARAMETER HEPassword
        (DEPRECATED) Password for Hurricane Electric using their Dynamic TXT API.

        The password should match the password set in the user interface for the hostname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HECredential (Get-Credential)

        Adds a TXT record using after providing credentials in a prompt.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$HECredential,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$HEUsername,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$HEPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"

    # get plain text versions of the pscredential we can work with
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HEUsername = $HECredential.UserName
        $HEPassword = $HECredential.GetNetworkCredential().Password
    }

    # URI escape the credentials
    $userEscaped = [uri]::EscapeDataString($HEUsername)
    $passEscaped = [uri]::EscapeDataString($HEPassword)

    # build the form body
    $addBody = "hostname=$userEscaped&password=$passEscaped&txt=."
    $iwrArgs = @{
        Uri = 'https://dyn.dns.he.net/nic/update'
        Method = 'Post'
        Body = $addBody
        ErrorAction = 'Stop'
    }

    try {
        $response = Invoke-WebRequest @iwrArgs @script:UseBasic
    } catch { throw }

    $reStatus = '^(nochg|good)'

    if (-Not($response.Content -match $reStatus)) {
        Write-Warning "Unexpected result status while resetting record: $($response.Content)"
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Hurricane Electric using their Dynamic TXT API.

    .DESCRIPTION
        Remove a DNS TXT record from Hurricane Electric using their Dynamic TXT API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HECredential
        Username and password for Hurricane Electric using their Dynamic TXT API. 

        The username should match the hostname being used to ultimately store the challenge. The password should match the password set
        in the user interface for the hostname.

    .PARAMETER HEUsername
        (DEPRECATED) Username for Hurricane Electric using their Dynamic TXT API.

        The username should match the hostname being used to ultimately store the challenge.

    .PARAMETER HEPassword
        (DEPRECATED) Password for Hurricane Electric using their Dynamic TXT API.

        The password should match the password set in the user interface for the hostname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HECredential (Get-Credential)

        Removes a TXT record using after providing credentials in a prompt.
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
