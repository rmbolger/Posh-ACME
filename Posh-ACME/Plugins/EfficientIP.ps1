function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$EIPUsername,
        [Parameter(Mandatory,Position=3)]
        [securestring]$EIPPassword,
        [Parameter(Mandatory,Position=4)]
        [string]$EIPHostname,
        [Parameter(Mandatory,Position=5)]
        [string]$EIPDNSName,
        [Parameter(Mandatory,Position=6)]
        [string]$EIPView,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure secret to a normal string
    $EIPPasswordInsecure = [pscredential]::new('a',$EIPPassword).GetNetworkCredential().Password

    $Endpoint = "dns_rr_add"
    $queryParams += @{rr_name = $RecordName}
    $queryParams += @{value1 = $TxtValue}
    $queryParams += @{rr_type = "TXT"}
    $queryParams += @{rr_ttl = "15"}

    $queryString = ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
    $Parameters = "dnsview_name=$($EIPView)&add_flag=new_only&check_value=yes&dns_name=$($EIPDNSName)&$($queryString)"

    $Response = Send-EfficientIPRequest -Parameters $Parameters -Endpoint $Endpoint -Method POST -EIPUsername $EIPUsername -EIPPassword $EIPPasswordInsecure -EIPHostname $EIPHostname

   <#
    .SYNOPSIS
        Add a DNS TXT record to EfficientIP SOLIDServer.

    .DESCRIPTION
        Add a DNS TXT record to EfficientIP SOLIDServer.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER EIPUsername
        The EfficientIP SOLIDServer Username.

    .PARAMETER EIPPassword
        The EfficientIP SOLIDServer Password.

    .PARAMETER EIPHostname
        The EfficientIP SOLIDServer Hostname.

    .PARAMETER EIPDNSName
        The EfficientIP SOLIDServer DNS Name.

    .PARAMETER EIPView
        The EfficientIP SOLIDServer View.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "EIP Password" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user' $secret 'eip.local' 'smart.local' 'external'

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
        [string]$EIPUsername,
        [Parameter(Mandatory,Position=3)]
        [securestring]$EIPPassword,
        [Parameter(Mandatory,Position=4)]
        [string]$EIPHostname,
        [Parameter(Mandatory,Position=5)]
        [string]$EIPDNSName,
        [Parameter(Mandatory,Position=6)]
        [string]$EIPView,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    Try{
        # convert the secure secret to a normal string
        $EIPPasswordInsecure = [pscredential]::new('a',$EIPPassword).GetNetworkCredential().Password

        $DNSRRRecord = Get-EIPDNSRecordID -Name $RecordName -TxtValue $TxtValue -DNSName $EIPDNSName -View $EIPView -EIPUsername $EIPUsername -EIPPassword $EIPPasswordInsecure -EIPHostname $EIPHostname
        If($DNSRRRecord.count -eq 0){
           Write-Verbose "No records exist, exiting..."
           Break
        }

        $DNSRRRecord | % {
            $ID = $_
            $Endpoint = "dns_rr_delete"
            $Parameters = "rr_id=$($ID)"
            $Response = Send-EfficientIPRequest -Parameters $Parameters -Endpoint $Endpoint -Method DELETE -EIPUsername $EIPUsername -EIPPassword $EIPPasswordInsecure -EIPHostname $EIPHostname
        }
    }Catch{}

    <#
    .SYNOPSIS
        Remove a DNS TXT record from EfficientIP SOLIDServer.

    .DESCRIPTION
        Remove a DNS TXT record from EfficientIP SOLIDServer.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER EIPUsername
        The EfficientIP SOLIDServer Username.

    .PARAMETER EIPPassword
        The EfficientIP SOLIDServer Password.

    .PARAMETER EIPHostname
        The EfficientIP SOLIDServer Hostname.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "EIP Password" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'user' $secret 'eip.local'

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

Function Send-EfficientIPRequest {
   Param(
      [Parameter(Mandatory,Position=0)][String]$EIPHostname,
      [Parameter(Mandatory,Position=1)][String]$EIPUsername,
      [Parameter(Mandatory,Position=2)][String]$EIPPassword,
      [Parameter(Mandatory,Position=3)][String]$Endpoint,
      [Parameter(Mandatory,Position=4)][String]$Method = "Get",
      [Parameter(Mandatory,Position=5)][String]$Parameters
   )

   begin {}

   process {
      $basicAuthValue = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $EIPUsername, $EIPPassword)))
      $Headers = @{
         "Authorization"="Basic $basicAuthValue"
         "Content-Type"="application/json"
         "Accept"="application/json"
         "charset"="utf-8"
      }
      $URI = "/rest/$($Endpoint)?$($Parameters)"
      $URL = "https://$($EIPHostname)$($URI)"

      $queryParams += @{Method = $Method}
      $queryParams += @{Headers = $Headers}
      $queryParams += @{Uri = $URL}

      Write-Verbose $queryParams | Out-String
      Try {
         $requests = Invoke-WebRequest @queryParams @script:UseBasic
         Return $requests
      } catch {
         if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Verbose -ForegroundColor Red "`nThe EfficientIP connection failed - Unauthorized`n"
         } else {
            Write-Verbose "Error connecting to EfficientIP"
            Write-Verbose "`n($_)`n"
         }
      }
   }

   end {}
}

Function Get-EIPDNSRecordID {
   Param(
      [Parameter(Mandatory,Position=0)][String]$EIPHostname,
      [Parameter(Mandatory,Position=1)][String]$EIPUsername,
      [Parameter(Mandatory,Position=2)][String]$EIPPassword,
      [Parameter(Mandatory,Position=0)][String]$Name,
      [Parameter(Mandatory,Position=0)][String]$TxtValue,
      [Parameter(Mandatory,Position=1)][String]$DNSName,
      [Parameter(Mandatory,Position=2)][String]$View
   )
   Try{
      $Endpoint = "dns_rr_list"
      $Parameters = "WHERE=(rr_full_name='$($Name)'+AND+value1='$($TxtValue)')+AND+(dns_name='$($DNSName)'+AND+dnsview_name='$($View)')"

      $Response = Send-EfficientIPRequest -Parameters $Parameters -Endpoint $Endpoint -Method GET -EIPUsername $EIPUsername -EIPPassword $EIPPassword -EIPHostname $EIPHostname

      If($Response.Content -ne $null){
        $ResponseContent = $Response.Content | ConvertFrom-Json
      } else {
        return $null
      }

      if ($ResponseContent -ne $null -and $ResponseContent.rr_id -ne $null) {
         return $ResponseContent.rr_id
      } else {
         return $null  # Or any appropriate default value you prefer
      }
   }Catch{}
}
