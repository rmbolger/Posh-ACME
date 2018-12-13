function Add-DnsTxtRoute53 {
    [CmdletBinding(DefaultParameterSetName='Keys')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=2)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=3)]
        [string]$R53SecretKeyInsecure,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # For now, we're going to use the AwsPowershell module for both types of credentials.
    # But my hope is to eventually remove the AwsPowershell module dependency (which is
    # currently 75 MB by itself) for people who use the Access/Secret key pair.

    # make sure the correct module is available for the PS edition
    if ($PSEdition -eq 'Core') { $modName = 'AwsPowershell.NetCore' } else { $modName = 'AwsPowershell' }
    if (!(Get-Module -ListAvailable $modName -Verbose:$false)) {
        throw "The $modName module is required to use this plugin."
    } else {
        Import-Module $modName -Verbose:$false
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Keys' {
            $keyPlain = (New-Object PSCredential "user",$R53SecretKey).GetNetworkCredential().Password
            $credParam = @{AccessKey=$R53AccessKey; SecretKey=$keyPlain}
            break
        }
        'KeysInsecure' {
            $credParam = @{AccessKey=$R53AccessKey; SecretKey=$R53SecretKeyInsecure}
            break
        }
        default {
            $credParam = @{ProfileName=$R53ProfileName}
        }
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName $credParam)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    # It's possible there could already be a TXT record for this name with one or more existing
    # values and we don't want to overwrite them. So check first and add to it if it exists.
    $response = Get-R53ResourceRecordSet $zoneID $RecordName 'TXT' @credParam
    $rrSet = $response.ResourceRecordSets | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }
    if ($rrSet.ResourceRecords) {
        # add to the existing record
        $rrSet.ResourceRecords += @{Value="`"$TxtValue`""}
    } else {
        # create a new one
        $rrSet = New-Object Amazon.Route53.Model.ResourceRecordSet
        $rrSet.Name = $RecordName
        $rrSet.Type = 'TXT'
        $rrSet.TTL = 0
        $rrSet.ResourceRecords.Add(@{Value="`"$TxtValue`""})
    }

    # send the change
    Write-Verbose "Adding the record to zone ID $zoneID"
    $change = New-Object Amazon.Route53.Model.Change
    $change.Action = 'UPSERT'
    $change.ResourceRecordSet = $rrSet
    Edit-R53ResourceRecordSet -HostedZoneId $zoneID -ChangeBatch_Change $change @credParam | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record to a Route53 hosted zone.

    .DESCRIPTION
        This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKey
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretKey
        The Secret Key for the IAM account specified by -R53AccessKey. This SecureString version should only be used on Windows.

    .PARAMETER R53SecretKeyInsecure
        The Secret Key for the IAM account specified by -R53AccessKey. This standard String version should be used on non-Windows OSes.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AwsPowershell module. This only works if the AwsPowershell module is installed.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53ProfileName 'myprofile'

        Add a TXT record using a profile name saved in the AwsPowershell module.

    .EXAMPLE
        $seckey = Read-Host -Prompt 'Secret Key:' -AsSecureString
        PS C:\>Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKey $seckey

        Add a TXT record using an explicit Access Key and Secret key from Windows.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKeyInsecure 'yyyyyyyy'

        Add a TXT record using an explicit Access Key and Secret key from a non-Windows OS.
    #>
}

function Remove-DnsTxtRoute53 {
    [CmdletBinding(DefaultParameterSetName='Keys')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=2)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=3)]
        [string]$R53SecretKeyInsecure,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # For now, we're going to use the AwsPowershell module for both types of credentials.
    # But my hope is to eventually remove the AwsPowershell module dependency (which is
    # currently 75 MB by itself) for people who use the Access/Secret key pair.

    switch ($PSCmdlet.ParameterSetName) {
        'Keys' {
            $keyPlain = (New-Object PSCredential "user",$R53SecretKey).GetNetworkCredential().Password
            $credParam = @{AccessKey=$R53AccessKey; SecretKey=$keyPlain}
            break
        }
        'KeysInsecure' {
            $credParam = @{AccessKey=$R53AccessKey; SecretKey=$R53SecretKeyInsecure}
            break
        }
        default {
            $credParam = @{ProfileName=$R53ProfileName}
        }
    }


    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName $credParam)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    # The TXT record for this name could potentially have multiple values and we only want to
    # remove this specific one.
    $response = Get-R53ResourceRecordSet $zoneID $RecordName 'TXT' @credParam
    $rrSet = $response.ResourceRecordSets | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }

    $change = New-Object Amazon.Route53.Model.Change
    $change.ResourceRecordSet = $rrSet

    if (!$rrSet) {
        Write-Verbose "TXT record for $Record name not found. Already deleted?"
        return
    } elseif ($rrSet.ResourceRecords.Count -gt 1) {
        # update the values to exclude one we want to delete
        $change.Action = 'UPSERT'
        $rrSet.ResourceRecords = $rrSet.ResourceRecords | Where-Object { $_.Value -ne "`"$TxtValue`"" }
    } else {
        # just delete the record
        $change.Action = 'DELETE'
    }

    # remove the record
    Write-Verbose "Removing the record from zone ID $zoneID"
    Edit-R53ResourceRecordSet -HostedZoneId $zoneID -ChangeBatch_Change $change @credParam | Out-Null

    <#
    .SYNOPSIS
        Remove a DNS TXT record from a Route53 hosted zone.

    .DESCRIPTION
        This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKey
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretKey
        The Secret Key for the IAM account specified by -R53AccessKey. This SecureString version should only be used on Windows.

    .PARAMETER R53SecretKeyInsecure
        The Secret Key for the IAM account specified by -R53AccessKey. This standard String version should be used on non-Windows OSes.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AwsPowershell module. This only works if the AwsPowershell module is installed.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53ProfileName 'myprofile'

        Remove a TXT record using a profile name saved in the AwsPowershell module.

    .EXAMPLE
        $seckey = Read-Host -Prompt 'Secret Key:' -AsSecureString
        PS C:\>Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKey $seckey

        Remove a TXT record using an explicit Access Key and Secret key from Windows.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKeyInsecure 'yyyyyyyy'

        Remove a TXT record using an explicit Access Key and Secret key from a non-Windows OS.
    #>
}

function Save-DnsTxtRoute53 {
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

function Get-AwsHash {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$Data
    )
    # Need a SHA256 hash in lowercase hex with no dashes
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($Data))
    return ([BitConverter]::ToString($hash) -replace '-','').ToLower()
}

function Invoke-R53RestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$AccessKey,
        [Parameter(Mandatory,Position=1)]
        [string]$SecretKey,
        [Parameter(Position=2)]
        [string]$Method='GET',
        [Parameter(Position=3)]
        [string]$Endpoint='/',                  # e.g. CanonicalUri like "/2013-04-01/hostedzone"
        [Parameter(Position=4)]
        [string]$QueryString=[String]::Empty,   # e.g. CanonicalQueryString like "name=example.com&type=TXT"
        [Parameter(Position=5)]
        [string]$Data=[String]::Empty
    )

    # The convoluted process that is authenticating against AWS using Signature Version 4
    # https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html

    # Since we're only ever using Route53, we can hard code a few things
    $awsHost = 'route53.amazonaws.com'
    $region = 'us-east-1'
    $service = 'route53'
    $terminator = 'aws4_request'


    # For some reason we need two differently formatted date strings
    $now = [DateTimeOffset]::UtcNow
    $nowDate = $now.ToString("yyyyMMdd")
    $nowDateTime = $now.ToString("yyyyMMddTHHmmssZ")

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    $CanonicalHeaders = "host:$awsHost`nx-amz-date:$nowDateTime`n"
    Write-Debug "CanonicalHeaders:`n$CanonicalHeaders"
    $SignedHeaders = "host;x-amz-date"

    $CanonicalRequest = "$Method`n$Endpoint`n$QueryString`n$CanonicalHeaders`n$SignedHeaders`n$((Get-AwsHash $Data))"
    Write-Debug "CanonicalRequest:`n$CanonicalRequest"
    $CanonicalRequestHash = Get-AwsHash $CanonicalRequest

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    $CredentialScope = "$nowDate/$region/$service/$terminator"

    $StringToSign = "AWS4-HMAC-SHA256`n$nowDateTime`n$CredentialScope`n$CanonicalRequestHash"
    Write-Debug "StringToSign:`n$StringToSign"

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes("AWS4$SecretKey")
    $kDate = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($nowDate))

    $hmac.Key = $kDate
    $kRegion = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($region))

    $hmac.Key = $kRegion
    $kService = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($service))

    $hmac.Key = $kService
    $kSigning = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($terminator))

    $hmac.Key = $kSigning
    $signature = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($StringToSign))
    $sigHex = ([BitConverter]::ToString($signature) -replace '-','').ToLower()
    Write-Debug "Signature:`n$sigHex"

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-add-signature-to-request.html
    $Authorization = "AWS4-HMAC-SHA256 Credential=$AccessKey/$CredentialScope, SignedHeaders=$SignedHeaders, Signature=$sigHex"
    Write-Debug "Auth:`n$Authorization"

    # build the request params header hashtable
    $headers = @{
        'x-amz-date' = $nowDateTime
        Authorization = $Authorization
    }
    $uri = "https://$awsHost$($Endpoint)"
    if ([String]::Empty -ne $QueryString) {
        $uri += "?$QueryString"
    }
    Write-Debug "Uri: $uri"

    try {
        if ('Get' -eq $Method) {
            $response = Invoke-RestMethod $uri -Headers $headers @script:UseBasic
        } else {
            $response = Invoke-RestMethod $uri -Headers $headers -Method Post @script:UseBasic
        }
        return $response

    } catch { throw }
}

function Get-R53ZoneId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CredParam
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:R53RecordZones) { $script:R53RecordZones = @{} }

    # check for the record in the cache
    if ($script:R53RecordZones.ContainsKey($RecordName)) {
        return $script:R53RecordZones.$RecordName
    }

    # get the list of available public zones
    $zones = Get-R53HostedZoneList @CredParam | Where-Object { -not $_.Config.PrivateZone }

    # Since Route53 could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )."
        Write-Verbose "Checking $zoneTest"

        if ($zoneTest -in $zones.Name) {
            $zoneID = ($zones | Where-Object { $_.Name -eq $zoneTest }).Id
            $script:R53RecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}
