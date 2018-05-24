function Add-DnsTxtExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add DNS provider specific parameters after $TxtValue and
    # before $ExtraParams. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to add the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Add a DNS TXT record to <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add DNS provider specific parameters after $TxtValue and
    # before $ExtraParams. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to remove the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Remove a DNS TXT record from <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtExample {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add DNS provider specific parameters before $ExtraParams. Make sure
    # their names are unique across all existing plugins. But make
    # sure common ones across this plugin are the same.

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, remove
    # the $MyAPIVar parameters and just leave the body empty.

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxtExample

        Commits changes for pending DNS TXT record modifications.

    #>
}

############################
# Helper Functions
############################

# Add additional functions here if necessary.
# Make sure they're uniquely named and try to follow
# verb-noun naming guidelines.
# https://msdn.microsoft.com/en-us/library/ms714428
