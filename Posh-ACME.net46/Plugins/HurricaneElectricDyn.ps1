function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential[]]$HEDynCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

    # get the cred that matches the record
    $cred = $HEDynCredential | Where-Object { $RecordName -eq $_.UserName }
    if (-not $cred) {
        throw "HEDynCredential did not contain any matches for $RecordName."
    }

    # get plain text password we can work with
    $HEPassword = $cred.GetNetworkCredential().Password

    # build the post query
    $queryParams = @{
        Uri = 'https://dyn.dns.he.net/nic/update'
        Method = 'Post'
        Body = @{
            hostname = $RecordName
            password = $HEPassword
            txt = $TxtValue
        }
        ErrorAction = 'Stop'
        Verbose = $false
    }

    try {
        Write-Debug "POST $($queryParams.Uri)`nhostname = $RecordName, txt = $TxtValue"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch { throw }

    if ($response -notmatch '^(nochg|good)') {
        throw "Unexpected result status while adding record: $response"
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hurricane Electric using their Dynamic TXT API.

    .DESCRIPTION
        Add a DNS TXT record to Hurricane Electric using their Dynamic TXT API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HEDynCredential
        One or more PSCredential objects where the username is the full DNS record
        name being updated and the password is the key/password for dynamically
        updating that record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HEDynCredential (Get-Credential)

        Adds a TXT record using after providing credentials in a prompt.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential[]]$HEDynCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required

    .DESCRIPTION
        This provider does not really support deleting the TXT record that was created.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HEDynCredential
        One or more PSCredential objects where the username is the full DNS record
        name being updated and the password is the key/password for dynamically
        updating that record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required

    .DESCRIPTION
        This provider does not require calling this function to save DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
