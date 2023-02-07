function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [PSCredential]$IlaitCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $Domain = Find-IlaitZone -Credential $IlaitCredential $RecordName

    New-IlaitDnsRecord -Credential $IlaitCredential $Domain.customer.id $Domain.id $RecordName TXT $TxtValue 3600 | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record to Ilait.

    .DESCRIPTION
        Add a DNS TXT record to Ilait.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IlaitCredential
        Basic authentication credential for an Ilait user account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -IlaitCredential (Get-Credential)

        Adds a TXT record for the specified site with the specified value.
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
        [PSCredential]$IlaitCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $Domain = Find-IlaitZone -Credential $IlaitCredential $RecordName

    $DnsRecords = Get-IlaitDnsRecord -Credential $IlaitCredential $Domain.customer.id $Domain.id
    $DnsRecords | Where-Object { ($_.name -eq $RecordName) -and ($_.record_type -eq "TXT") -and ($_.content -eq "`"$TxtValue`"") } | ForEach-Object {
        Remove-IlaitDnsRecord -Credential $IlaitCredential $Domain.customer.id $Domain.id $_.id | Out-Null
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Ilait.

    .DESCRIPTION
        Remove a DNS TXT record from Ilait.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IlaitCredential
        Basic authentication credential for an Ilait user account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -IlaitCredential (Get-Credential)

        Removes a TXT record for the specified site with the specified value.
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

# API documentation:
# https://download.ilait.se/68721d2c99ff7fc9fa0c5bfe3dc4b4d2/63db7c1c/docs/ilait_api_documentation_4.1.1.pdf

$XmlHeader = "<?xml version=""1.0"" encoding=""UTF-8""?>"

function Export-IlaitXmlBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[string]$RequestType,
        [Parameter(Mandatory)]
		$RequestArgs
	)
    $Xml = $XmlHeader
    $Xml += "<$RequestType>"
    foreach ($arg in $RequestArgs.GetEnumerator()) {
        if ($arg.Value) {
            $Xml += "<$($arg.Key)>$($arg.Value)</$($arg.Key)>"
        }
    }
    $Xml += "</$RequestType>"
    $Xml
}

function Invoke-IlaitRestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCredential]$Credential,
        [Parameter(Position=1)]
        [string]$Path,
        [string]$Method = "Get",
        [string]$Body,
        [parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Passthrough
    )
    $restArgs = @{ }
    if ($Body) {
        $restArgs.Body = $Body
        $restArgs.ContentType = "application/xml"
    }
    Invoke-RestMethod -Credential $Credential -Method $Method "https://partner.ilait.com/api/$Path" @script:UseBasic @restArgs
}

function Get-IlaitCustomer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[PSCredential]$Credential
	)
    $res = Invoke-IlaitRestMethod -Credential $Credential "customers"
    $res.customers.customer
}

function Get-IlaitDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[PSCredential]$Credential,
        [Parameter(Mandatory)]
		[int]$Customer
	)
    $res = Invoke-IlaitRestMethod -Credential $Credential "customers/$Customer/domains"
    $res.domains.domain
}

function Find-IlaitZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[PSCredential]$Credential,
        [Parameter(Mandatory)]
		[string]$DomainName
	)
    $customers = Get-IlaitCustomer -Credential $Credential
    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        foreach ($customer in $customers) {
            $domain = Get-IlaitDomain -Credential $Credential $customer.id | Where-Object name -eq $zoneTest
            if ($domain) {
                $domain | Add-Member customer $customer
                return $domain
            }
        }
    }
}

function Get-IlaitDnsRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[PSCredential]$Credential,
        [Parameter(Mandatory)]
		[int]$Customer,
        [Parameter(Mandatory)]
		[int]$Domain
	)
    $res = Invoke-IlaitRestMethod -Credential $Credential "customers/$Customer/domains/$Domain/dns_records"
    $res.dns_records.dns_record
}

function Set-IlaitDnsRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[PSCredential]$Credential,
        [Parameter(Mandatory)]
		[int]$Customer,
        [Parameter(Mandatory)]
		[int]$Domain,
        [Parameter(Mandatory)]
		[int]$DnsRecord,
		[string]$Name,
		[string]$RecordType,
		[string]$Content,
		[int]$Ttl
	)
    $xmlArgs = @{
        name = $Name
        record_type = $RecordType
        content = $Content
        ttl = $Ttl
    }
    $body = Export-IlaitXmlBody dns_record $xmlArgs
    $res = Invoke-IlaitRestMethod -Credential $Credential -Method Put "customers/$Customer/domains/$Domain/dns_records/$DnsRecord" -Body $body
    $res.dns_record
}

function New-IlaitDnsRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
		[PSCredential]$Credential,
        [Parameter(Mandatory)]
		[int]$Customer,
        [Parameter(Mandatory)]
		[int]$Domain,
		[string]$Name,
		[string]$RecordType,
		[string]$Content,
		[int]$Ttl
	)
    $xmlArgs = @{
        name = $Name
        record_type = $RecordType
        content = $Content
        ttl = $Ttl
    }
    $body = Export-IlaitXmlBody dns_record $xmlArgs
    $res = Invoke-IlaitRestMethod -Credential $Credential -Method Post "customers/$Customer/domains/$Domain/dns_records" -Body $body
    $res.dns_record
}

function Remove-IlaitDnsRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCredential]$Credential,
        [Parameter(Mandatory)]
        [int]$Customer,
        [Parameter(Mandatory)]
		[int]$Domain,
        [Parameter(Mandatory)]
		[int]$DnsRecord
	)
    $res = Invoke-IlaitRestMethod -Credential $Credential -Method Delete "customers/$Customer/domains/$Domain/dns_records/$DnsRecord"
    $res.dns_record
}
