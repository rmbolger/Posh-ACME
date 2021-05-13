function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
		[Parameter(Mandatory=$false)]
		[Switch]$ManualNonInteractive = $false,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Saving TXT record to display when Save-DnsTxt is called."
    if (!$script:ManualTxtAdd) { $script:ManualTxtAdd = @() }
    $script:ManualTxtAdd += [pscustomobject]@{Record=$RecordName;TxtValue=$TxtValue}
	$script:ManualNonInteractive = $ManualNonInteractive

    <#
    .SYNOPSIS
        Stores the TXT record to display when Save-DnsTxt is called.

    .DESCRIPTION
        This plugin requires user interaction and should not be used for any certificates that require automated renewals. Renewal operations will skip these.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ManualNonInteractive
        A flag that, if set, prevents user-prompts. Useful i.e. for automation scenarios where user input is not possible.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Stores TXT record data for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Saving TXT record to display when Save-DnsTxt is called."
    if (!$script:ManualTxtRemove) { $script:ManualTxtRemove = @() }
    $script:ManualTxtRemove += [pscustomobject]@{Record=$RecordName;TxtValue=$TxtValue}

    <#
    .SYNOPSIS
        Stores the TXT record to display when Save-DnsTxt is called.

    .DESCRIPTION
        This plugin requires user interaction and should not be used for any certificates that require automated renewals. Renewal operations will skip these.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Stores TXT record data for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ($script:ManualTxtAdd -and $script:ManualTxtAdd.Count -gt 0) {

        Write-Host
        Write-Host "Please create the following TXT records:"
        Write-Host "------------------------------------------"
        $script:ManualTxtAdd | ForEach-Object {
            Write-Host "$($_.Record) -> $($_.TxtValue)"
        }
        Write-Host "------------------------------------------"
        Write-Host

        # clear out the variable so we don't notify twice
        Remove-Variable ManualTxtAdd -Scope Script
		
		if (-not $script:ManualNonInteractive) {
			Read-Host -Prompt "Press any key to continue." | Out-Null
		}
		else {
			Write-Host "Non-interactive mode, starting wait."
			Write-Host
		}
    }

    if ($script:ManualTxtRemove -and $script:ManualTxtRemove.Count -gt 0) {

        Write-Host
        Write-Host "Please remove the following TXT records:"
        Write-Host "------------------------------------------"
        $script:ManualTxtRemove | ForEach-Object {
            Write-Host "$($_.Record) -> $($_.TxtValue)"
        }
        Write-Host "------------------------------------------"
        Write-Host

        # clear out the variable so we don't notify twice
        Remove-Variable ManualTxtRemove -Scope Script
    }

    <#
    .SYNOPSIS
        Displays the TXT records that need to be manually created or removed by the user.

    .DESCRIPTION
        This function outputs the pending TXT records to be created and waits for user confirmation to continue.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
