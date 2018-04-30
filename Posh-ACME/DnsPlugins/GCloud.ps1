function Add-DnsTxtGCloud {
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

    # Do work here to add the TXT record

    <#
    .SYNOPSIS
        Add a DNS TXT record to Google Cloud DNS

    .DESCRIPTION
        Add a DNS TXT record to Google Cloud DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtGCloud '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtGCloud {
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

    # Do work here to remove the TXT record

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Google Cloud DNS

    .DESCRIPTION
        Remove a DNS TXT record from Google Cloud DNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtGCloud '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtGCloud {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. Google Cloud DNS doesn't require a save step

    <#
    .SYNOPSIS
        Not required for Google Cloud DNS.

    .DESCRIPTION
        Google Cloud DNS does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
