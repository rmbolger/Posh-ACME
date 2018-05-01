#Requires -Modules DnsServer

function Add-DnsTxtWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    <#
    .SYNOPSIS
        Add a DNS TXT record to a Windows DNS server

    .DESCRIPTION
        This plugin requires the "DnsServer" PowerShell module to be installed. On Windows Server OSes, you can install it with "Install-WindowsFeature RSAT-DNS-Server". On Windows client OSes, you will need to download and install the RSAT tools for your OS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtWindows '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    <#
    .SYNOPSIS
        Remove a DNS TXT record from a Windows DNS server

    .DESCRIPTION
        This plugin requires the "DnsServer" PowerShell module to be installed. On Windows Server OSes, you can install it with "Install-WindowsFeature RSAT-DNS-Server". On Windows client OSes, you will need to download and install the RSAT tools for your OS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtWindows '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtWindows {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. Windows doesn't require a save step

    <#
    .SYNOPSIS
        Not required for Windows.

    .DESCRIPTION
        Windows does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################
