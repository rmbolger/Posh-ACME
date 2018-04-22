function Add-DnsTxtManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Host "Create TXT record for: $RecordName"
    Write-Host "TXT Value: $TxtValue"
    Write-Host

    Read-Host -Prompt "Press any key to continue once the record has been created"

    <#
    .SYNOPSIS
        Displays TXT record data to add to your DNS server manually.

    .DESCRIPTION
        This plugin requires user interaction and should not be used for any certificates that require automated renewals. Renewal operations will skip these.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtManual '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Displays TXT record data for the specified site with the specified value.
    #>
}

function Remove-DnsTxtManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Host "Delete TXT record for: $RecordName"
    Write-Host "TXT Value: $TxtValue"
    Write-Host

    Read-Host -Prompt "Press any key to continue once the record has been deleted"

    <#
    .SYNOPSIS
        Displays TXT record data to remove from your DNS server manually.

    .DESCRIPTION
        This plugin requires user interaction and should not be used for any certificates that require automated renewals. Renewal operations will skip these.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtManual '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Displays TXT record data for the specified site with the specified value.
    #>
}

function Save-DnsTxtManual {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Manual DNS modification doesn't require a save step.

    <#
    .SYNOPSIS
        Not required for Manual plugin.

    .DESCRIPTION
        Manual plugin does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
