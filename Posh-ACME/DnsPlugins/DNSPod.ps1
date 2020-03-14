function Add-DnsTxtDNSPod {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$DNSPodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$DNSPodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 3)]
        [string]$DNSPodPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )


    # grab the cleartext credential if the secure version was used
    # and make the auth token
    if (!$script:authToken) {
        if ($PSCmdlet.ParameterSetName -eq 'Secure') {
            Get-DNSPodAuthToken $DNSPodCredential
        }
        else {
            Get-DNSPodAuthToken $DNSPodUsername $DNSPodPwdInsecure
        }
    }

    ########

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-DNSPodTxtRecord $RecordName $TxtValue
    }
    catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }
    else {
        # add a new record
        try {
            Write-Verbose "Adding $RecordName with value $TxtValue"

            $recShort = $RecordName -ireplace [regex]::Escape(".$($zone.name)"), [string]::Empty
            $ApiEndpoint = 'https://api.dnspod.com/Record.Create'
            $body = "user_token=$($script:authToken)&format=json&domain_id=$($zone.id)&sub_domain=$recShort&record_type=TXT&record_line=default&value=$txtValue&ttl=1"
            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DNSPodUA

            if ($response.status.code -ne 1 -and $response.status.code -ne 31) {
                throw $response.status.message
            }
        }
        catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to DNSPod.

    .DESCRIPTION
        Uses the DNSPod DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSPodCredential
        The pscredentials object with your DNSPod account credential. Can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DNSPodUsernameInsecure
        Your DNSPod e-mail account. This standard String version may be used on any OS.

    .PARAMETER DNSPodPwdInsecure
        Your DNSPod account password. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "DNSPod Token" -AsSecureString
        PS C:\>Add-DnsTxtDNSPod '_acme-challenge.example.com' 'txt-value' $token

        Adds the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Add-DnsTxtDNSPod '_acme-challenge.example.com' 'txt-value' 'my-token'

        Adds the specified TXT record with the specified value using a plaintext token.
    #>
}

function Remove-DnsTxtDNSPod {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$DNSPodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$DNSPodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 3)]
        [string]$DNSPodPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )


    # grab the cleartext credential if the secure version was used
    # and make the auth token
    if (!$script:authToken) {
        if ($PSCmdlet.ParameterSetName -eq 'Secure') {
            Get-DNSPodAuthToken $DNSPodCredential
        }
        else {
            Get-DNSPodAuthToken $DNSPodUsername $DNSPodPwdInsecure
        }
    }

    ########

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-DNSPodTxtRecord $RecordName $TxtValue
    }
    catch { throw }

    if ($rec) {
        # delete the record
        try {
            Write-Verbose "Removing $RecordName with value $TxtValue"

            $ApiEndpoint = 'https://api.dnspod.com/Record.Remove'
            $body = "user_token=$($script:authToken)&format=json&domain_id=$($zone.id)&record_id=$($rec.id)"
            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DNSPodUA

            if ($response.status.code -ne 1 -and $response.status.code -ne 8) {
                throw $response.status.message
            }
        }
        catch { throw }
    }
    else {

        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from DNSPod.

    .DESCRIPTION
        Uses the DNSPod DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSPodCredential
        The pscredentials object with your DNSPod account credential. Can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DNSPodUsernameInsecure
        Your DNSPod e-mail account. This standard String version may be used on any OS.

    .PARAMETER DNSPodPwdInsecure
        Your DNSPod account password. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "DNSPod Token" -AsSecureString
        PS C:\>Remove-DnsTxtDNSPod '_acme-challenge.example.com' 'txt-value' $token

        Removes the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Remove-DnsTxtDNSPod '_acme-challenge.example.com' 'txt-value' 'my-token'

        Removes the specified TXT record with the specified value using a plaintext token.
    #>
}

function Save-DnsTxtDNSPod {
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
# https://www.dnspod.com/docs/info.html

function Get-DNSPodTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DNSPodRecordZones) { $script:DNSPodRecordZones = @{ } }

    # check for the record in the cache
    if ($script:DNSPodRecordZones.ContainsKey($RecordName)) {
        $zone = $script:DNSPodRecordZones.$RecordName
    }

    if (!$zone) {

        try {
            # get zone
            $ApiEndpoint = 'https://api.dnspod.com/Domain.List'

            $body = "user_token=$($script:authToken)&format=json"

            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DNSPodUA

            if ($response.status.code -ne 1) {
                throw $response.status.message
            }
            else {
                [array]$hostedZones = $response.domains
            }

            $zone = $hostedZones | Where-Object { $RecordName -match $_.name }
            Remove-Variable hostedZones, response

            #save zone to cache
            $script:DNSPodRecordZones.$RecordName = $zone
        }
        catch { throw }

        if (!$zone) {
            throw "Failed to find hosted zone for $RecordName"
        }

    }

        try {

            # separate the portion of the name that doesn't contain the zone name
            $recShort = $RecordName -ireplace [regex]::Escape(".$($zone.name)"), [string]::Empty

            # get record
            $ApiEndpoint = 'https://api.dnspod.com/Record.List'

            $body = "user_token=$($script:authToken)&format=json&domain_id=$($zone.id)"

            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DNSPodUA

            if ($response.status.code -ne 1) {
                throw $response.status.message
            }
            else {
                $rec = $response.records | Where-Object { $_.name -eq $recShort -and $_.type -eq 'TXT' -and $_.value -eq $txtValue }
            }
        }
        catch { throw }

    return @($zone, $rec)
}

function Get-DNSPodAuthToken {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 0)]
        [pscredential]$DNSPodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 0)]
        [string]$DNSPodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 1)]
        [string]$DNSPodPwdInsecure
    )

    if ($PSCmdlet.ParameterSetName -eq 'Secure') {
        $DNSPodUsername = $DNSPodCredential.UserName
        $DNSPodPwdInsecure = $DNSPodCredential.GetNetworkCredential().Password
    }

    # Set global user-agent
    if (!$script:DNSPodUA) { $script:DNSPodUA = 'POSH-ACME DNSPod plugin 1.0' }

    $ApiEndpoint = 'https://api.dnspod.com/Auth'

    $body = "login_email=$DNSPodUsername&login_password=$DNSPodPwdInsecure&format=json"
    try {
        $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DNSPodUA
        # username and password not needed anymore, remove variables for better safety
        Remove-Variable DNSPodUsername, DNSPodPwdInsecure
    }
    catch {
        throw
    }

    if ($response.status.code -ne 1) {
        throw $response.status.message
    }
    # Set global AuthToken
    Write-Debug "Auth token = $($response.user_token)"
    $script:authToken = $response.user_token
}
