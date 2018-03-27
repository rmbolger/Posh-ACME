function Add-DnsChallengeManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments=$true)]
        $Splat
    )

    Write-Host "Create TXT record for: $RecordName"
    Write-Host "TXT Value: $TxtValue"
    Write-Host

    Read-Host -Prompt "Press any key to continue once the record has been created"
}

function Remove-DnsChallengeManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(ValueFromRemainingArguments=$true)]
        $Splat
    )

    Write-Host "Delete TXT record for: $RecordName"
    Write-Host

    Read-Host -Prompt "Press any key to continue once the record has been deleted"
}

