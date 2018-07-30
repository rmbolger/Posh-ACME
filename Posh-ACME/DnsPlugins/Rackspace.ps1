function Add-DnsTxtRackspace {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$RSUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$RSApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$RSApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )




    <#
    .SYNOPSIS
        Add a DNS TXT record to Rackspace Cloud DNS

    .DESCRIPTION
        Add a DNS TXT record to Rackspace Cloud DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RSUsername
        The username of your Rackspace Cloud account.

    .PARAMETER RSApiKey
        The API Key associated with your Rackspace Cloud account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER RSApiKeyInsecure
        The API Key associated with your Rackspace Cloud account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "Rackspace API Key" -AsSecureString
        PS C:\>Add-DnsTxtNS1 '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' $key

        Adds a TXT record using a securestring object for RSApiKey. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxtNS1 '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' 'xxxxxxxx'

        Adds a TXT record using a standard string object for RSApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxtRackspace {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$RSUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$RSApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$RSApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )





    <#
    .SYNOPSIS
        Remove a DNS TXT record from Rackspace Cloud DNS

    .DESCRIPTION
        Remove a DNS TXT record from Rackspace Cloud DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RSUsername
        The username of your Rackspace Cloud account.

    .PARAMETER RSApiKey
        The API Key associated with your Rackspace Cloud account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER RSApiKeyInsecure
        The API Key associated with your Rackspace Cloud account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "Rackspace API Key" -AsSecureString
        PS C:\>Remove-DnsTxtNS1 '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' $key

        Removes a TXT record using a securestring object for RSApiKey. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxtNS1 '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' 'xxxxxxxx'

        Removes a TXT record using a standard string object for RSApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Save-DnsTxtRackspace {
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

############################
# Helper Functions
############################
