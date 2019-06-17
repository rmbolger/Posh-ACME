
function Add-DnsTxtSimpleDNSPlus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$SdnsServer,
        [Parameter(Mandatory, Position = 3)]
        [string]$SdnsUser,
        [Parameter(Mandatory, Position = 4)]
        [string]$SdnsSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
	Ignore-SelfSignedCerts
    $apiRoot = "https://$($SdnsServer)/v2/zones"
	$p = $SdnsSecret | ConvertTo-SecureString -asPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential($SdnsUser, $p)


    $zone = Find-SimpleDNSPlusZone -RecordName $RecordName -SdnsServer $SdnsServer -SdnsUser $SdnsUser -SdnsSecret $SdnsSecret
    $recShort = ($RecordName -split ".$zone")[0]

	# Get a list of existing TXT records for this record name
    try {
		$recs = (Invoke-RestMethod "$apiRoot/$zone/records" -Credential $credential @script:UseBasic -EA Stop ) `
			| Where-Object {$_.Type -eq "TXT" -And $_.Name -eq $RecordName}	
	} catch { throw }
	if (-not $recs -or $TxtValue -notin $recs.data) {
        $bodyJson = "[{`"Name`":`"$RecordName`",`"Type`":`"TXT`",`"TTL`":600,`"Data`":`"$TxtValue`"}]"

        try {
            Write-Debug "Sending $bodyJson"
            Invoke-RestMethod "$apiRoot/$zone/records" `
                -Method Patch -Credential $credential -Body $bodyJson `
                -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
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

    .PARAMETER SdnsServer
        The Simple DNS Plus Server Name or IP.

    .PARAMETER SdnsUser
        The Simple DNS Plus HTTP API Username.

    .PARAMETER SdnsSecret
        The Simple DNS Plus HTTP API Password/Secret.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtSimpleDNSPlus '_acme-challenge.site1.example.com' '199.123.123.123' 'superuser' 'supersecretpassword'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtSimpleDNSPlus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$SdnsServer,
        [Parameter(Mandatory, Position = 3)]
        [string]$SdnsUser,
        [Parameter(Mandatory, Position = 4)]
        [string]$SdnsSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
	
	Ignore-SelfSignedCerts
    $apiRoot = "https://$($SdnsServer)/v2/zones"
	$p = $SdnsSecret | ConvertTo-SecureString -asPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential($SdnsUser, $p)

	$zone = Find-SimpleDNSPlusZone -RecordName $RecordName -SdnsServer $SdnsServer -SdnsUser $SdnsUser -SdnsSecret $SdnsSecret

    $recShort = ($RecordName -split ".$zone")[0]

    # Get a list of existing Challenge TXT records for this record name, 
	# Simple DNS Plus API returns full fqdns as each record, so no need to parse/shorten it. 
    try {
        $recs = (Invoke-RestMethod "$apiRoot/$zone/records" -Credential $credential @script:UseBasic -EA Stop ) `
			| Select-Object -Property * -ExcludeProperty TTL `
			| Where-Object {$_.Type -eq "TXT" -And $_.Name -eq $RecordName}	
    } catch { throw }
    if (-not $recs -or $TxtValue -notin $recs.Data) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # Txt record values in simple dns plus contains double quotes encasing the string. 
		# So for it to JSON properly, we must remove those double quotes from the string.
		$recs | foreach {$_.Data = $_.Data -replace '"',''}

		$recToDelete = $recs | WHERE-Object {$_.Data -eq $TxtValue} 
		$recToDelete | Add-Member -NotePropertyName Remove -NotePropertyValue $true
		$bodyJson = ConvertTo-Json @($recToDelete) -Compress

        try {
            Write-Debug "Sending $bodyJson"
            Invoke-RestMethod "$apiRoot/$zone/records" `
                -Method Patch -Credential $credential -Body $bodyJson `
                -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
        } catch { throw }

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

    .PARAMETER SdnsServer
        The Simple DNS Plus Server Name or IP.

    .PARAMETER SdnsUser
        The Simple DNS Plus HTTP API Username.

    .PARAMETER SdnsSecret
        The Simple DNS Plus HTTP API Password/Secret.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtSimpleDNSPlus '_acme-challenge.site1.example.com' '199.123.123.123' 'superuser' 'supersecretpassword'

        Removes a TXT record for the specified site with the specified value.
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
function Ignore-SelfSignedCerts {
	try {
		Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
		Add-Type -TypeDefinition @" 
	using System.Net;
	using System.Security.Cryptography.X509Certificates;
	public class TrustAllCertsPolicy : ICertificatePolicy {
	public bool CheckValidationResult(
	ServicePoint srvPoint, X509Certificate certificate,
	WebRequest request, int certificateProblem) {
	return true;
	}
	}
		"@
		Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White
	}
	catch {
		Write-Host $_ -ForegroundColor "Yellow"
	}
		[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

    <#
    .SYNOPSIS
        Because most Simple DNS Plus Server installations have Self-Signed Certs or Invalid Certs for the HTTPS API, 
		it is necessary to allow Powershell Invoke-RestRestMethod to make Https Calls without failing https.

    .DESCRIPTION
        Allow All Certs regardless of validation, and fix powershell issue where sometimes TLS10/11/12 not enabled causing 
		requests to fail.

    .EXAMPLE
        Ignore-SelfSignedCerts
        Allows All Certs.
    #>
}
function Find-SimpleDNSPlusZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$SdnsServer,
        [Parameter(Mandatory, Position = 2)]
        [string]$SdnsUser,
        [Parameter(Mandatory, Position = 3)]
        [string]$SdnsSecret,
    )

	Ignore-SelfSignedCerts
    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:SdnsRecordZones) { $script:SdnsRecordZones = @{} }

    # check for the record in the cache
    if ($script:SDnsRecordZones.ContainsKey($RecordName)) {
        return $script:SdnsRecordZones.$RecordName
    }

    $apiRoot = "https://$($SdnsServer)/v2/zones"
	$p = $SdnsSecret | ConvertTo-SecureString -asPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential($SdnsUser, $p)

    # get the list of available zones
    try {
        $zones = (Invoke-RestMethod $apiRoot -Credential $credential @script:UseBasic -EA Stop) `
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
    for ($i = 1; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones) {
            $zoneName = $zones | Where-Object { $_ -eq $zoneTest }
            $script:SdnsRecordZones.$RecordName = $zoneName
            return $zoneName
        }
    }

    return $null

    <#
    .SYNOPSIS
        Finds the appropriate DNS zone for the supplied record

    .DESCRIPTION
        Finds the appropriate DNS zone for the supplied record

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER SdnsServer
        The Simple DNS Plus Server Name or IP.

    .PARAMETER SdnsUser
        The Simple DNS Plus HTTP API Username.

    .PARAMETER SdnsSecret
        The Simple DNS Plus HTTP API Password/Secret.

    .EXAMPLE
        Find-SimpleDnsPlusZone -RecordName '_acme-challenge.site1.example.com' -SdnsServer '199.123.123.123' -SdnsUser 'adminuser' -SdnsSecret 'SuperSecretPassword'

        Finds the appropriate DNS zone for the supplied record
    #>
}
