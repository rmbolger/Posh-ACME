#Requires -Modules AwsPowershell

function Add-DnsTxtRoute53 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [string]$R53AccessKeyId,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretAccessKey,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # For now, we're going to use the AwsPowershell module for both types of credentials.
    # But my hope is to eventually remove the AwsPowershell module dependency (which is
    # currently 75 MB by itself) for people who use the Access/Secret key pair.

    if ('Keys' -eq $PSCmdlet.ParameterSetName) {
        $credParam = @{AccessKey=$R53AccessKeyId; SecretKey=((New-Object PSCredential "user",$R53SecretAccessKey).GetNetworkCredential().Password)}
    } else {
        $credParam = @{ProfileName=$R53ProfileName}
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName $credParam)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }





    <#
    .SYNOPSIS
        Add a DNS TXT record to a Route53 hosted zone.

    .DESCRIPTION
        This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKeyId
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretAccessKey
        The Secret Key for the IAM account specified by -R53AccessKeyId.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AwsPowershell module. This only works if the AwsPowershell module is installed.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtRoute53 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [string]$R53AccessKeyId,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretAccessKey,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # For now, we're going to use the AwsPowershell module for both types of credentials.
    # But my hope is to eventually remove the AwsPowershell module dependency (which is
    # currently 75 MB by itself) for people who use the Access/Secret key pair.

    if ('Keys' -eq $PSCmdlet.ParameterSetName) {
        $credParam = @{AccessKey=$R53AccessKeyId; SecretKey=((New-Object PSCredential "user",$R53SecretAccessKey).GetNetworkCredential().Password)}
    } else {
        $credParam = @{ProfileName=$R53ProfileName}
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName $credParam)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from a Route53 hosted zone.

    .DESCRIPTION
        This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKeyId
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretAccessKey
        The Secret Key for the IAM account specified by -R53AccessKeyId.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AwsPowershell module. This only works if the AwsPowershell module is installed.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtRoute53 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. Route53 doesn't require a save step

    <#
    .SYNOPSIS
        Not required for Route53.

    .DESCRIPTION
        Route53 does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

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

    # get the list of available zones
    $zones = Get-R53HostedZoneList @CredParam

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
