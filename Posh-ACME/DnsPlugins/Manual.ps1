function Add-DnsTxtManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    Write-Host "Create TXT record for: $RecordName"
    Write-Host "TXT Value: $TxtValue"
    Write-Host

    Read-Host -Prompt "Press any key to continue once the record has been created"
}

function Remove-DnsTxtManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    Write-Host "Delete TXT record for: $RecordName"
    Write-Host

    Read-Host -Prompt "Press any key to continue once the record has been deleted"
}

function Save-DnsTxtManual {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    # Manual DNS modification doesn't require a save step.
}
