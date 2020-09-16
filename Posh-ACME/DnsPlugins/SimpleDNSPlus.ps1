function Add-DnsTxtSimpleDNSPlus {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$SdnsApiRoot,
        [Parameter(ParameterSetName='Secure')]
        [pscredential]$SdnsCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$SdnsUser,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$SdnsPassword,
        [switch]$SdnsIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "$($SdnsApiRoot)/zones"

    # create a pscredential from insecure args if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secpass = ConvertTo-SecureString $SdnsPassword -AsPlainText -Force
        $SdnsCred = New-Object PSCredential ($SdnsUser,$secpass)
    }
    $credSplat = @{}
    if ($SdnsCred) { $credSplat.Credential = $SdnsCred }

    try {
        # ignore cert validation for the duration of the call
        if ($SdnsIgnoreCert) { Set-SdnsCertIgnoreOn }

        $zone = Find-SimpleDNSPlusZone -RecordName $RecordName -SdnsApiRoot $SdnsApiRoot -CredSplat $credSplat

        # Get a list of existing TXT records for this record name
        try {
            $recs = (Invoke-RestMethod "$apiRoot/$zone/records" @credSplat @script:UseBasic -EA Stop ) |
                Where-Object {$_.Type -eq "TXT" -And $_.Name -eq $RecordName}
        } catch { throw }

        if (-not $recs -or "`"$TxtValue`"" -notin $recs.data) {
            $bodyJson = ConvertTo-Json @(@{Name=$RecordName;Type='TXT';TTL=600;'Data'=$TxtValue}) -Compress

            try {
                Write-Debug "Sending $bodyJson"
                Invoke-RestMethod "$apiRoot/$zone/records" `
                    -Method Patch @credSplat -Body $bodyJson `
                    -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
            } catch { throw }

        } else {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        }

    } finally {
        # return cert validation back to normal
        if ($SdnsIgnoreCert) { Set-SdnsCertIgnoreOff }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Simple DNS Plus Server.

    .DESCRIPTION
        Add a DNS TXT record to Simple DNS Plus Server.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SdnsApiRoot
        The root URL of the Simple DNS Plus Server API. For example, http://dns.example.com:8053 or http://dns.example.com:8053/v2

    .PARAMETER SdnsCred
        The HTTP API credentials required to authenticate.

    .PARAMETER SdnsUser
        The HTTP API Username.

    .PARAMETER SdnsSecret
        The HTTP API Password.

    .PARAMETER SdnsIgnoreCert
        Use this switch to prevent certificate errors when your Simple DNS Plus server is using a self-signed or other untrusted SSL certificate. When passing parameters via hashtable, set it as a boolean such as @{SdnsIgnoreCert=$true}.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtSimpleDNSPlus '_acme-challenge.example.com' 'txtvalue' -SdnsApiRoot http://dns.example.com:8053

        Adds a TXT record using anonymous authentication.

    .EXAMPLE
        $pArgs = @{ SdnsApiRoot = 'http://dns.example.com:8053'; SdnsCred = (Get-Credential); SdnsIgnoreCert = $true }
        PS C:\>Add-DnsTxtSimpleDNSPlus '_acme-challenge.site1.example.com' 'txtvalue' @pArgs

        Adds a TXT record using credentials and ignores certificate validation.

    .EXAMPLE
        $pArgs = @{ SdnsApiRoot = 'http://dns.example.com:8053'; SdnsUser = 'admin'; SdnsPassword = 'xxxxxxxx' }
        PS C:\>Add-DnsTxtSimpleDNSPlus '_acme-challenge.site1.example.com' 'txtvalue' @pArgs

        Adds a TXT record using plain text credentials.
    #>
}

function Remove-DnsTxtSimpleDNSPlus {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$SdnsApiRoot,
        [Parameter(ParameterSetName='Secure')]
        [pscredential]$SdnsCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$SdnsUser,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$SdnsPassword,
        [switch]$SdnsIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "$($SdnsApiRoot)/zones"

    # create a pscredential from insecure args if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secpass = ConvertTo-SecureString $SdnsPassword -AsPlainText -Force
        $SdnsCred = New-Object PSCredential ($SdnsUser,$secpass)
    }
    $credSplat = @{}
    if ($SdnsCred) { $credSplat.Credential = $SdnsCred }

    try {
        # ignore cert validation for the duration of the call
        if ($SdnsIgnoreCert) { Set-SdnsCertIgnoreOn }

        $zone = Find-SimpleDNSPlusZone -RecordName $RecordName -SdnsApiRoot $SdnsApiRoot -CredSplat $credSplat

        # Get a list of existing Challenge TXT records for this record name,
        # Simple DNS Plus API returns full fqdns as each record, so no need to parse/shorten it.
        try {
            $recs = (Invoke-RestMethod "$apiRoot/$zone/records" @credSplat @script:UseBasic -EA Stop) |
                Select-Object -Property * -ExcludeProperty TTL |
                Where-Object { $_.Type -eq "TXT" -And $_.Name -eq $RecordName }
        } catch { throw }

        if (-not $recs -or "`"$TxtValue`"" -notin $recs.Data) {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        } else {
            # Txt record values in simple dns plus contains double quotes encasing the string.
            # So for it to JSON properly, we must remove those double quotes from the string.
            $recs | ForEach-Object { $_.Data = $_.Data -replace '"','' }

            $recToDelete = $recs | Where-Object {$_.Data -eq $TxtValue}
            $recToDelete | Add-Member -NotePropertyName Remove -NotePropertyValue $true
            $bodyJson = ConvertTo-Json @($recToDelete) -Compress

            try {
                Write-Debug "Sending $bodyJson"
                Invoke-RestMethod "$apiRoot/$zone/records" `
                    -Method Patch @credSplat -Body $bodyJson `
                    -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
            } catch { throw }

        }

    } finally {
        # return cert validation back to normal
        if ($SdnsIgnoreCert) { Set-SdnsCertIgnoreOff }
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Simple DNS Plus Server.

    .DESCRIPTION
        Remove a DNS TXT record from Simple DNS Plus Server.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SdnsApiRoot
        The root URL of the Simple DNS Plus Server API. For example, http://dns.example.com:8053 or http://dns.example.com:8053/v2

    .PARAMETER SdnsCred
        The HTTP API credentials required to authenticate.

    .PARAMETER SdnsUser
        The HTTP API Username.

    .PARAMETER SdnsSecret
        The HTTP API Password.

    .PARAMETER SdnsIgnoreCert
        Use this switch to prevent certificate errors when your Simple DNS Plus server is using a self-signed or other untrusted SSL certificate. When passing parameters via hashtable, set it as a boolean such as @{SdnsIgnoreCert=$true}.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtSimpleDNSPlus '_acme-challenge.example.com' 'txtvalue' -SdnsApiRoot http://dns.example.com:8053

        Removes a TXT record using anonymous authentication.

    .EXAMPLE
        $pArgs = @{ SdnsApiRoot = 'http://dns.example.com:8053'; SdnsCred = (Get-Credential); SdnsIgnoreCert = $true }
        PS C:\>Remove-DnsTxtSimpleDNSPlus '_acme-challenge.site1.example.com' 'txtvalue' @pArgs

        Removes a TXT record using credentials and ignores certificate validation.

    .EXAMPLE
        $pArgs = @{ SdnsApiRoot = 'http://dns.example.com:8053'; SdnsUser = 'admin'; SdnsPassword = 'xxxxxxxx' }
        PS C:\>Remove-DnsTxtSimpleDNSPlus '_acme-challenge.site1.example.com' 'txtvalue' @pArgs

        Removes a TXT record using plain text credentials.
    #>
}

function Save-DnsTxtSimpleDNSPlus {
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

# https://simpledns.com/help/how-to-use-the-http-api

function Find-SimpleDNSPlusZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$SdnsApiRoot,
        [Parameter(Position = 2)]
        [hashtable]$CredSplat
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:SdnsRecordZones) { $script:SdnsRecordZones = @{} }

    # check for the record in the cache
    if ($script:SDnsRecordZones.ContainsKey($RecordName)) {
        return $script:SdnsRecordZones.$RecordName
    }

    $apiRoot = "$($SdnsApiRoot)/zones"

    # get the list of available zones
    try {
        $zones = (Invoke-RestMethod $apiRoot @credSplat @script:UseBasic -EA Stop) `
            | Where-Object {$_.Type -eq "primary"} `
            | Select-Object -ExpandProperty Name
    } catch { throw }

    # We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones) {
            $zoneName = $zones | Where-Object { $_ -eq $zoneTest }
            $script:SdnsRecordZones.$RecordName = $zoneName
            return $zoneName
        }
    }

    return $null
}

# These cert ignore helpers rely on some TLS initialization code that runs during the
# module import. So if you're dot sourcing the plugin file to test, you need to account
# for that.
function Set-SdnsCertIgnoreOn {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if (-not $script:UseBasic.SkipCertificateCheck) {
            # temporarily set skip to true
            $script:UseBasic.SkipCertificateCheck = $true
            # remember that we did
            $script:SdnsUnsetIgnoreAfter = $true
        }
    } else {
        # Desktop edition
        Write-Debug "Ignoring certs"
        [CertValidation]::Ignore()
    }
}

function Set-SdnsCertIgnoreOff {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if ($script:SdnsUnsetIgnoreAfter) {
            $script:UseBasic.SkipCertificateCheck = $false
            Remove-Variable SdnsUnsetIgnoreAfter -Scope Script
        }
    } else {
        # Desktop edition
        Write-Debug "Un-Ignoring certs"
        [CertValidation]::Restore()
    }
}
