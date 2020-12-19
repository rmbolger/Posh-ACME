function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$IBServer,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$IBCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBPassword,
        [string]$IBView='default',
        [switch]$IBIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # create a pscredential from insecure args if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secpass = ConvertTo-SecureString $IBPassword -AsPlainText -Force
        $IBCred = New-Object PSCredential ($IBUsername,$secpass)
    }

    $recUrl = "https://$IBServer/wapi/v1.0/record:txt?name=$RecordName&text=$TxtValue&view=$IBView"

    try {
        # ignore cert validation for the duration of the call
        if ($IBIgnoreCert) { Set-IBCertIgnoreOn }

        # check if the record already exists
        $response = Invoke-RestMethod -Uri $recUrl -Method Get -Credential $IBCred @script:UseBasic

        if ($response -and $response.'_ref') {
            Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
        } else {
            # add the record
            Write-Verbose "Adding $RecordName with value $TxtValue"
            Invoke-RestMethod -Uri "$recUrl&ttl=0" -Method Post -Credential $IBCred @script:UseBasic | Out-Null
        }

    } finally {
        # return cert validation back to normal
        if ($IBIgnoreCert) { Set-IBCertIgnoreOff }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Infoblox.

    .DESCRIPTION
        Add a DNS TXT record to Infoblox.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IBServer
        The IP or hostname of the Infoblox server.

    .PARAMETER IBCred
        Credentials for Infoblox that have permission to write TXT records to the specified zone. This PSCredential option should only be used from Windows.

    .PARAMETER IBUsername
        The Infoblox username that has permission to write TXT records to the specified zone. This should be used from non-Windows.

    .PARAMETER IBPassword
        The password for the IBUsername parameter. This should be used from non-Windows.

    .PARAMETER IBView
        The name of the DNS View for the specified zone. Defaults to 'default'.

    .PARAMETER IBIgnoreCert
        Use this switch to prevent certificate errors when your Infoblox server is using a self-signed or other untrusted SSL certificate. When passing parameters via hashtable, set it as a boolean such as @{IBIgnoreCert=$true}.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>$pluginArgs = @{IBServer='gridmaster.example.com'; IBCred=$cred; IBView='External'; IBIgnoreCert=$true}
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' @pluginArgs

        Adds a TXT record for the specified site/value on Windows.

    .EXAMPLE
        $pluginArgs = @{IBServer='gridmaster.example.com'; IBUsername='myuser'; IBPassword='xxxxxxxx'; IBView='External'; IBIgnoreCert=$true}
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' @pluginArgs

        Adds a TXT record for the specified site/value on non-Windows.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$IBServer,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$IBCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBPassword,
        [string]$IBView='default',
        [switch]$IBIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # create a pscredential from insecure args if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secpass = ConvertTo-SecureString $IBPassword -AsPlainText -Force
        $IBCred = New-Object PSCredential ($IBUsername,$secpass)
    }

    try {
        # ignore cert validation for the duration of the call
        if ($IBIgnoreCert) { Set-IBCertIgnoreOn }

        # query the _ref for the txt record object we want to delete
        $recUrl = "https://$IBServer/wapi/v1.0/record:txt?name=$RecordName&text=$TxtValue&view=$IBView"
        $response = Invoke-RestMethod -Uri $recUrl -Method Get -Credential $IBCred @script:UseBasic

        if ($response -and $response.'_ref') {
            # delete the record
            $delUrl = "https://$IBServer/wapi/v1.0/$($response.'_ref')"
            Write-Verbose "Removing $RecordName with value $TxtValue"
            Invoke-RestMethod -Uri $delUrl -Method Delete -Credential $IBCred @script:UseBasic | Out-Null
        } else {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        }

    } finally {
        # return cert validation back to normal
        if ($IBIgnoreCert) { Set-IBCertIgnoreOff }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Infoblox.

    .DESCRIPTION
        Remove a DNS TXT record from Infoblox.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IBServer
        The IP or hostname of the Infoblox server.

    .PARAMETER IBCred
        Credentials for Infoblox that have permission to write TXT records to the specified zone. This PSCredential option should only be used from Windows.

    .PARAMETER IBUsername
        The Infoblox username that has permission to write TXT records to the specified zone. This should be used from non-Windows.

    .PARAMETER IBPassword
        The password for the IBUsername parameter. This should be used from non-Windows.

    .PARAMETER IBView
        The name of the DNS View for the specified zone. Defaults to 'default'.

    .PARAMETER IBIgnoreCert
        Use this switch to prevent certificate errors when your Infoblox server is using a self-signed or other untrusted SSL certificate. When passing parameters via hashtable, set it as a boolean such as @{IBIgnoreCert=$true}.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>$pluginArgs = @{IBServer='gridmaster.example.com'; IBCred=$cred; IBView='External'; IBIgnoreCert=$true}
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' @pluginArgs

        Removes a TXT record for the specified site/value on Windows.

    .EXAMPLE
        $pluginArgs = @{IBServer='gridmaster.example.com'; IBUsername='myuser'; IBPassword='xxxxxxxx'; IBView='External'; IBIgnoreCert=$true}
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' @pluginArgs

        Removes a TXT record for the specified site/value on non-Windows.
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

function Set-IBCertIgnoreOn {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if (-not $script:UseBasic.SkipCertificateCheck) {
            # temporarily set skip to true
            $script:UseBasic.SkipCertificateCheck = $true
            # remember that we did
            $script:IBUnsetIgnoreAfter = $true
        }

    } else {
        # Desktop edition
        [CertValidation]::Ignore()
    }
}

function Set-IBCertIgnoreOff {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if ($script:IBUnsetIgnoreAfter) {
            $script:UseBasic.SkipCertificateCheck = $false
            Remove-Variable IBUnsetIgnoreAfter -Scope Script
        }

    } else {
        # Desktop edition
        [CertValidation]::Restore()
    }
}
