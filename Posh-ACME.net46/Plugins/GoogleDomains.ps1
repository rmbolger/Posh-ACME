function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential[]]$GDomCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the cred that matches the record
    $cred = $GDomCredential | Where-Object {
        $RecordName -like "*$($_.UserName)"
    }
    if (-not $cred) {
        throw "GDomCredential did not contain any matches for $RecordName."
    }
    $domain = $cred.UserName
    $token = $cred.GetNetworkCredential().Password

    # The API doesn't care if you try to add a record that already exists.
    # So just send it regardless of whether it exists or not.
    $postParams = @{
        Uri = "https://acmedns.googleapis.com/v1/acmeChallengeSets/$($domain):rotateChallenges"
        Method = 'POST'
        Body = @{
            accessToken = $token
            recordsToAdd = @(
                @{
                    fqdn = $RecordName
                    digest = $TxtValue
                }
            )
        } | ConvertTo-Json
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    # add new record
    try {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Write-Debug "POST $($postParams.Uri)`n$($postParams.Body.Replace($token,'<REDACTED>'))"
        $null = Invoke-RestMethod @postParams @script:UseBasic
    } catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Google Domains

    .DESCRIPTION
        Add a DNS TXT record to Google Domains

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDomCredential
        One or more PSCredential objects where the username is a domain hosted in Google Domains and the password is the ACME DNS API Token for that domain.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential -Username 'example.com'
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -GDomCredential $cred

        Adds a TXT record for the specified site and value with the specified credential.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential[]]$GDomCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the cred that matches the record
    $cred = $GDomCredential | Where-Object {
        $RecordName -like "*$($_.UserName)"
    }
    if (-not $cred) {
        throw "GDomCredential did not contain any matches for $RecordName."
    }
    $domain = $cred.UserName
    $token = $cred.GetNetworkCredential().Password

    # The API doesn't care if you try to remove a record that doesn't exist.
    # So try to delete regardless of whether it exists or not.
    $postParams = @{
        Uri = "https://acmedns.googleapis.com/v1/acmeChallengeSets/$($domain):rotateChallenges"
        Method = 'POST'
        Body = @{
            accessToken = $token
            recordsToRemove = @(
                @{
                    fqdn = $RecordName
                    digest = $TxtValue
                }
            )
        } | ConvertTo-Json
        ContentType = 'application/json'
        Verbose = $false
        ErrorAction = 'Stop'
    }

    # remove record
    try {
        Write-Verbose "Removing a TXT record for $RecordName with value $TxtValue"
        Write-Debug "POST $($postParams.Uri)`n$($postParams.Body.Replace($token,'<REDACTED>'))"
        $null = Invoke-RestMethod @postParams @script:UseBasic
    } catch { throw }

    <#
    .SYNOPSIS
        Remove an ACME Challenge DNS TXT record from Google Domains.

    .DESCRIPTION
        Remove an ACME Challenge DNS TXT record from Google Domains.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDomCredential
        One or more PSCredential objects where the username is a domain hosted in Google Domains and the password is the ACME DNS API Token for that domain.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential -Username 'example.com'
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -GDomCredential $cred

        Removes a TXT record for the specified site and value with the specified credential.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments, DontShow)]
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

# https://developers.google.com/domains/acme-dns/
