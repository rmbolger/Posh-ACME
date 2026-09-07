function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$DNSMintToken,
        [string]$DNSMintApiRoot = 'https://dnsmint.com/api/httpreq',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Invoke-DNSMintChallenge 'present' $RecordName $TxtValue $DNSMintToken $DNSMintApiRoot

    <#
    .SYNOPSIS
        Publish a DNS TXT record to DNSMint.

    .DESCRIPTION
        Publish a DNS TXT record to DNSMint.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSMintToken
        A DNSMint API key with the dns01:write scope, which may be narrowed to a single hostname.

    .PARAMETER DNSMintApiRoot
        The DNSMint challenge API root. Defaults to https://dnsmint.com/api/httpreq.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'API Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.q7k4m2.example.dev' 'txt-value' -DNSMintToken $token

        Publishes the challenge for a DNSMint hostname.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$DNSMintToken,
        [string]$DNSMintApiRoot = 'https://dnsmint.com/api/httpreq',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Invoke-DNSMintChallenge 'cleanup' $RecordName $TxtValue $DNSMintToken $DNSMintApiRoot

    <#
    .SYNOPSIS
        Withdraw a DNS TXT record from DNSMint.

    .DESCRIPTION
        Withdraw a DNS TXT record from DNSMint.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSMintToken
        A DNSMint API key with the dns01:write scope, which may be narrowed to a single hostname.

    .PARAMETER DNSMintApiRoot
        The DNSMint challenge API root. Defaults to https://dnsmint.com/api/httpreq.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'API Key' -AsSecureString
        Remove-DnsTxt '_acme-challenge.q7k4m2.example.dev' 'txt-value' -DNSMintToken $token

        Withdraws the challenge for a DNSMint hostname.
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
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://dnsmint.com/api-reference

function Invoke-DNSMintChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateSet('present','cleanup')]
        [string]$Action,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=3)]
        [securestring]$DNSMintToken,
        [Parameter(Mandatory,Position=4)]
        [string]$DNSMintApiRoot
    )

    # DNSMint operates the domain and derives the hostname from the challenge
    # name itself, so there is no zone to find and no record ID to track: the
    # value published is the value removed.
    $token = [pscredential]::new('a',$DNSMintToken).GetNetworkCredential().Password
    $headers = @{ Authorization = "Bearer $token" }
    $body = @{ fqdn = $RecordName; value = $TxtValue } | ConvertTo-Json

    $uri = '{0}/{1}' -f $DNSMintApiRoot.TrimEnd('/'), $Action
    Write-Verbose "Sending $Action for $RecordName"

    try {
        Invoke-RestMethod $uri -Method Post -Body $body -Headers $headers `
            -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
    } catch {
        # DNSMint explains refusals in the body - a key narrowed to another
        # hostname, a name that is not live - and that is more use than the
        # status code on its own.
        $detail = $_.ErrorDetails.Message
        if ($detail) {
            throw "DNSMint refused the $Action for $($RecordName): $detail"
        }
        throw
    }
}
