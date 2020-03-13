function Add-DnsTxtDnspod {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$DnspodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$DnspodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 3)]
        [string]$DnspodPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    
    # grab the cleartext credential if the secure version was used
    # and make the auth token
    if (!$script:authToken) {
        if ($PSCmdlet.ParameterSetName -eq 'Secure') {
            Get-DnspodAuthToken $DnspodCredential
        }
        else {
            Get-DnspodAuthToken $DnspodUsername $DnspodPwdInsecure
        }
    }

    ########

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-DnspodTxtRecord $RecordName $TxtValue $AuthHeader
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
            $body = "user_token=$authToken&format=json&domain_id=$($zone.id)&sub_domain=$recShort&record_type=TXT&record_line=default&value=$txtValue&ttl=1"
            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DnspodUA

            if (!$($response.status.code -ne 1 -and $response.status.code -ne 31)) {
                throw $response.status.message
            }
        }
        catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Dnspod.

    .DESCRIPTION
        Uses the Dnspod DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DnspodCredential
        The Dnspod admin token generated for your account. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DnspodUsernameInsecure
        The Dnspod admin token generated for your account. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "Dnspod Token" -AsSecureString
        PS C:\>Add-DnsTxtDnspod '_acme-challenge.example.com' 'txt-value' $token

        Adds the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Add-DnsTxtDnspod '_acme-challenge.example.com' 'txt-value' 'my-token'

        Adds the specified TXT record with the specified value using a plaintext token.
    #>
}

function Remove-DnsTxtDnspod {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$DnspodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$DnspodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 3)]
        [string]$DnspodPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    
    # grab the cleartext credential if the secure version was used
    # and make the auth token
    if (!$script:authToken) {
        if ($PSCmdlet.ParameterSetName -eq 'Secure') {
            Get-DnspodAuthToken $DnspodCredential
        }
        else {
            Get-DnspodAuthToken $DnspodUsername $DnspodPwdInsecure
        }
    }

    ########

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-DnspodTxtRecord $RecordName $TxtValue $AuthHeader
    }
    catch { throw }

    if ($rec) {
        # delete the record
        try {
            Write-Verbose "Removing $RecordName with value $TxtValue"
            
            $ApiEndpoint = 'https://api.dnspod.com/Record.Remove'
            $body = "user_token=$authToken&format=json&domain_id=$($zone.id)&record_id=$($rec.id)"
            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DnspodUA

            if (!$($response.status.code -ne 1 -and $response.status.code -ne 8)) {
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
        Remove a DNS TXT record from Dnspod.

    .DESCRIPTION
        Uses the Dnspod DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DnspodCredential
        The Dnspod admin token generated for your account. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DnspodUsernameInsecure
        The Dnspod admin token generated for your account. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "Dnspod Token" -AsSecureString
        PS C:\>Remove-DnsTxtDnspod '_acme-challenge.example.com' 'txt-value' $token

        Removes the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Remove-DnsTxtDnspod '_acme-challenge.example.com' 'txt-value' 'my-token'

        Removes the specified TXT record with the specified value using a plaintext token.
    #>
}

function Save-DnsTxtDnspod {
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

function Get-DnspodTxtRecord {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$DnspodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$DnspodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 3)]
        [string]$DnspodPwdInsecure
    )

    if (!$script:authToken) {
        if ($PSCmdlet.ParameterSetName -eq 'Secure') {
            Get-DnspodAuthToken $DnspodCredential
        }
        else {
            Get-DnspodAuthToken $DnspodUsername $DnspodPwdInsecure
        }
    } 

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DnspodRecordZones) { $script:DnspodRecordZones = @{ } }

    # check for the record in the cache
    if ($script:DnspodRecordZones.ContainsKey($RecordName)) {
        $zone = $script:DnspodRecordZones.$RecordName
    }

    if (!$zone) {

        try {
            # get zone
            $ApiEndpoint = 'https://api.dnspod.com/Domain.List'
    
            $body = "user_token=$authToken&format=json"
            
            $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DnspodUA

            if ($response.status.code -ne 1) {
                throw $response.status.message
            }
            else {
                [array]$hostedZones = $response.domains
            }
        
            $zone = $hostedZones | Where-Object { $RecordName -match $_.name }
            Remove-Variable hostedZones, response

            #save zone to cache
            $script:DnspodRecordZones.$RecordName = $zone
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
    
        $body = "user_token=$authToken&format=json&domain_id=$($zone.id)"
            
        $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DnspodUA

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

function Get-DnspodAuthToken {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 0)]
        [pscredential]$DnspodCredential,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 0)]
        [string]$DnspodUsername,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 1)]
        [string]$DnspodPwdInsecure
    )

    if ($PSCmdlet.ParameterSetName -eq 'Secure') {
        $DnspodUsername = $DnspodCredential.UserName
        $DnspodPwdInsecure = $DnspodCredential.GetNetworkCredential().Password
    }

    # Set global user-agent
    if (!$script:DnspodUA) { $script:DnspodUA = 'POSH-ACME Dnspod plugin 1.0' }

    $ApiEndpoint = 'https://api.dnspod.com/Auth?'

    $body = "login_email=$DnspodUsername&login_password=$DnspodPwdInsecure&format=json"
    try {
        $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Body $body -UserAgent $script:DnspodUA
        # username and password not needed anymore, remove variables for better safety
        Remove-Variable DnspodUsername, DnspodPwdInsecure
    }
    catch {
        throw
    }

    if ($response.status.code -ne 1) {
        throw $response.status.message
    }
    # Set global AuthToken
    $script:authToken = $response.dnspod.user_token
}