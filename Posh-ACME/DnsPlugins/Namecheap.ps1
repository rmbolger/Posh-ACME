function Add-DnsTxtNamecheap {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NCUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$NCApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$NCApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )



    <#
    .SYNOPSIS
        Add a DNS TXT record to Namecheap

    .DESCRIPTION
        Add a DNS TXT record to Namecheap

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NCUsername
        The username of your Namecheap account.

    .PARAMETER NCApiKey
        The API Key associated with your Namecheap account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER NCApiKeyInsecure
        The API Key associated with your Namecheap account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "API Key" -AsSecureString
        PS C:\>Add-DnsTxtRackspace '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' $key

        Adds a TXT record using a securestring object for NCApiKey. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxtRackspace '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' 'xxxxxxxx'

        Adds a TXT record using a standard string object for NCApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxtNamecheap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NCUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$NCApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$NCApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )



    <#
    .SYNOPSIS
        Remove a DNS TXT record from Namecheap

    .DESCRIPTION
        Remove a DNS TXT record from Namecheap

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NCUsername
        The username of your Namecheap account.

    .PARAMETER NCApiKey
        The API Key associated with your Namecheap account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER NCApiKeyInsecure
        The API Key associated with your Namecheap account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "Rackspace API Key" -AsSecureString
        PS C:\>Remove-DnsTxtRackspace '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' $key

        Removes a TXT record using a securestring object for NCApiKey. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxtRackspace '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' 'xxxxxxxx'

        Removes a TXT record using a standard string object for NCApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Save-DnsTxtNamecheap {
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
