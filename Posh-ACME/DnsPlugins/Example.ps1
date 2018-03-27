function Add-DnsChallengeExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$MyAPIVar1,
        [Parameter(Mandatory)]
        [int]$MyAPIVar2,
        [Parameter(ValueFromRemainingArguments=$true)]
        $Splat
    )

    # Do work here to add the TXT record

}

function Remove-DnsChallengeExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$MyAPIVar1,
        [Parameter(Mandatory)]
        [int]$MyAPIVar2,
        [Parameter(ValueFromRemainingArguments=$true)]
        $Splat
    )

    # Do work here to remove the TXT record

}

function Save-DnsChallengeExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MyAPIVar1,
        [Parameter(Mandatory)]
        [int]$MyAPIVar2,
        [Parameter(ValueFromRemainingArguments=$true)]
        $Splat
    )

    # Do work here to save or finalize changes performed by Add/Remove functions
}
