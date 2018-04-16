function Add-DnsTxtExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    # Add DNS provider specific parameters after $TxtValue and
    # before $Splat. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to add the TXT record

}

function Remove-DnsTxtExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    # Add DNS provider specific parameters after $TxtValue and
    # before $Splat. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to remove the TXT record

}

function Save-DnsTxtExample {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    # Add DNS provider specific parameters before $Splat. Make sure
    # their names are unique across all existing plugins. But make
    # sure common ones across this plugin are the same.

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, remove
    # the $MyAPIVar parameters and just leave the body empty.
}
