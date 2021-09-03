function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure', Mandatory, Position = 2)]
        [pscredential]$BlueCatCredential,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$BlueCatUsername,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$BlueCatPassword,
        [Parameter(Mandatory)]
        [string]$BlueCatUri,
        [Parameter(Mandatory)]
        [string]$BlueCatConfig,
        [Parameter(Mandatory)]
        [string]$BlueCatView,
        [Parameter(Mandatory)]
        [string[]]$BlueCatDeployTargets,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Until PS Core gets New-WebServiceProxy, this will be a Desktop only plugin
    if (-not $PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -ne "Desktop") {
        throw "The BlueCat plugin requires Windows PowerShell and is not supported on PowerShell Core."
    }

    # extract the plain text credentials
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $BlueCatUsername = $BlueCatCredential.UserName
        $BlueCatPassword = $BlueCatCredential.GetNetworkCredential().Password
    }

    $proxy = Get-BlueCatWsdlProxy -Username $BlueCatUsername -Password $BlueCatPassword -Uri $BlueCatUri
    $view = Get-View -ConfigurationName $BlueCatConfig -ViewName $BlueCatView -BlueCatProxy $proxy
    $parentZone = Get-ParentZone -AbsoluteName $RecordName -ViewId $view.id -BlueCatProxy $proxy
    $props = HashtableToString -Hashtable @{parentZoneName = $parentZone.absoluteName}
    $proxy.addTxtRecord($view.id, $RecordName, $TxtValue, -1, $props)

    <#
    .SYNOPSIS
        Add a DNS TXT record to BlueCat.

    .DESCRIPTION
        Use the BAM API to add a TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER BlueCatCredential
        BlueCat Username and Password.

    .PARAMETER BlueCatUsername
        (DEPRECATED) BlueCat Username.

    .PARAMETER BlueCatPassword
        (DEPRECATED) BlueCat Password.

    .PARAMETER BlueCatUri
        BlueCat API uri.

    .PARAMETER BlueCatConfig
        BlueCat Configuration name.

    .PARAMETER BlueCatView
        BlueCat DNS View name.

    .PARAMETER BlueCatDeployTargets
        List of BlueCat servers to deploy.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -BlueCatCredential $cred -BlueCatUri 'https://FQDN//Services/API' -BlueCatConfig 'foobar' -BlueCatView 'foobaz'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure', Mandatory, Position = 2)]
        [pscredential]$BlueCatCredential,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$BlueCatUsername,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$BlueCatPassword,
        [Parameter(Mandatory)]
        [string]$BlueCatUri,
        [Parameter(Mandatory)]
        [string]$BlueCatConfig,
        [Parameter(Mandatory)]
        [string]$BlueCatView,
        [Parameter(Mandatory)]
        [string[]]$BlueCatDeployTargets,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Until PS Core gets New-WebServiceProxy, this will be a Desktop only plugin
    if (-not $PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -ne "Desktop") {
        throw "The BlueCat plugin requires Windows PowerShell and is not supported on PowerShell Core."
    }

    # extract the plain text credentials
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $BlueCatUsername = $BlueCatCredential.UserName
        $BlueCatPassword = $BlueCatCredential.GetNetworkCredential().Password
    }

    $proxy = Get-BlueCatWsdlProxy -Username $BlueCatUsername -Password $BlueCatPassword -Uri $BlueCatUri
    $view = Get-View -ConfigurationName $BlueCatConfig -ViewName $BlueCatView -BlueCatProxy $proxy
    $parentZone = Get-ParentZone -AbsoluteName $RecordName -ViewId $view.id -BlueCatProxy $proxy
    $txtRecordName = ($RecordName -ireplace [regex]::Escape($parentZone.absoluteName), [string]::Empty).TrimEnd('.')
    $txtRecords = $proxy.getEntitiesByName($parentZone.id, $txtRecordName, "TXTRecord", 0, [int16]::MaxValue)
    $txtRecords = $txtRecords | ForEach-Object { (ConvertPSObjectToHashtable -InputObject $_) + (StringToHashtable -String $_.properties) }
    $txtRecord = $txtRecords | Where-Object { $_.txt -eq $TxtValue }
    if (!$txtRecord.name) {
        throw ("No text record found!")
    }
    $proxy.delete($txtRecord.id)

    <#
    .SYNOPSIS
        Remove a DNS TXT record from BlueCat.

    .DESCRIPTION
        Use the BAM API to remove a TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER BlueCatCredential
        BlueCat Username and Password.

    .PARAMETER BlueCatUsername
        (DEPRECATED) BlueCat Username.

    .PARAMETER BlueCatPassword
        (DEPRECATED) BlueCat Password.

    .PARAMETER BlueCatUri
        BlueCat API uri.

    .PARAMETER BlueCatConfig
        BlueCat Configuration name.

    .PARAMETER BlueCatView
        BlueCat DNS View name.

    .PARAMETER BlueCatDeployTargets
        List of BlueCat servers to deploy.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -BlueCatCredential $cred -BlueCatUri 'https://FQDN//Services/API' -BlueCatConfig 'foobar' -BlueCatView 'foobaz'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(ParameterSetName='Secure', Mandatory, Position = 2)]
        [pscredential]$BlueCatCredential,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$BlueCatUsername,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$BlueCatPassword,
        [Parameter(Mandatory)]
        [string]$BlueCatUri,
        [Parameter(Mandatory)]
        [string]$BlueCatConfig,
        [Parameter(Mandatory)]
        [string]$BlueCatView,
        [Parameter(Mandatory)]
        [string[]]$BlueCatDeployTargets,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Until PS Core gets New-WebServiceProxy, this will be a Desktop only plugin
    if (-not $PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -ne "Desktop") {
        throw "The BlueCat plugin requires Windows PowerShell and is not supported on PowerShell Core."
    }

    # extract the plain text credentials
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $BlueCatUsername = $BlueCatCredential.UserName
        $BlueCatPassword = $BlueCatCredential.GetNetworkCredential().Password
    }

    $proxy = Get-BlueCatWsdlProxy -Username $BlueCatUsername -Password $BlueCatPassword -Uri $BlueCatUri
    $config = $proxy.getEntityByName(0, $BlueCatConfig, "Configuration")
    Foreach ($ServerFQDN in $BlueCatDeployTargets) {
        $server = $proxy.getEntityByName($config.id, $ServerFQDN, "Server")
        $props = HashtableToString -Hashtable @{"services" = "DNS"}
        $proxy.deployServerConfig($server.id, $props)
    }

    <#
    .SYNOPSIS
        Deploy BlueCat changes to server(s).

    .DESCRIPTION
        Use the BAM API to deploy DNS changes.

    .PARAMETER BlueCatCredential
        BlueCat Username and Password.

    .PARAMETER BlueCatUsername
        (DEPRECATED) BlueCat Username.

    .PARAMETER BlueCatPassword
        (DEPRECATED) BlueCat Password.

    .PARAMETER BlueCatUri
        BlueCat API uri.

    .PARAMETER BlueCatConfig
        BlueCat Configuration name.

    .PARAMETER BlueCatView
        BlueCat DNS View name.

    .PARAMETER BlueCatDeployTargets
        List of BlueCat servers to deploy.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt -BlueCatUsername 'xxxxxxxx' -BlueCatPassword 'xxxxxxxx' `
        -BlueCatUri 'https://FQDN//Services/API' -BlueCatConfig 'foobar' -BlueCatDeployTargets @('FQDN1', 'FQDN2', 'FQDN3')
    #>
}

############################
# Helper Functions
############################

function Get-BlueCatWsdlProxy {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory)]
        [String]$Username,
        [Parameter(Mandatory)]
        [String]$Password,
        [Parameter(Mandatory)]
        [String]$Uri
    )
    $wsdlProxy = New-WebServiceProxy -Uri "$($Uri)?wsdl"
    $wsdlProxy.url = $Uri
    $cookieContainer = New-Object System.Net.CookieContainer
    $wsdlProxy.CookieContainer = $cookieContainer
    $wsdlProxy.login($Username, $Password)
    return $wsdlProxy
}

function HashtableToString {
    param(
        [Parameter(Mandatory)]
        [Hashtable]$Hashtable
    )

    $str = ""
    foreach ($i in $Hashtable.GetEnumerator()) {
        $str += "$($i.Name)=$($i.Value)|"
    }
    return $str
}

function StringToHashtable {
    param(
        [Parameter(Mandatory)]
        [String]$String
    )

    $hashtable = @{}
    $pairs = $String.split("|")
    foreach ($kv in $pairs) {
        $hashtable += ConvertFrom-StringData -StringData $kv
    }
    return $hashtable
}

function ConvertPSObjectToHashtable {
    param (
        [Parameter(Mandatory)]
        $InputObject
    )

    $hashtable = @{}
    foreach ($property in $InputObject.PSObject.Properties) {
        $hashtable[$property.Name] = $property.Value
    }
    return $hashtable
}

function Get-View {
    param (
        [Parameter(Mandatory)]
        [String]$ConfigurationName,
        [Parameter(Mandatory)]
        [String]$ViewName,
        [Parameter(Mandatory)]
        [System.Web.Services.Protocols.SoapHttpClientProtocol]$BlueCatProxy
    )

    $config = $BlueCatProxy.getEntityByName(0, $ConfigurationName, "Configuration")
    $BlueCatProxy.getEntityByName($config.id, $ViewName, "View")
}

function Get-ParentZone {
    param (
        [Parameter(Mandatory)]
        [String]$AbsoluteName,
        [Parameter(Mandatory)]
        [String]$ViewId,
        [Parameter(Mandatory)]
        [System.Web.Services.Protocols.SoapHttpClientProtocol]$BlueCatProxy
    )

    $zones = $AbsoluteName.split(".")
    [array]::Reverse($zones)
    $parentZone = @{ "id" = $ViewId }

    foreach ($el in $zones) {
        $zone = $BlueCatProxy.getEntityByName($parentZone.id, $el, "Zone")
        if (!$zone.id) {
            break
        }
        $parentZone = (ConvertPSObjectToHashtable -InputObject $zone) + (StringToHashtable -String $zone.properties)
    }

    if (!$parentZone.name) {
        throw ("No parent zone found!")
    }
    return $parentZone
}
