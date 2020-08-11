function Add-DnsTxtDynECT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$zone,
        [Parameter(Mandatory,Position=3)]
        [string]$user,
        [Parameter(Mandatory,Position=4)]
        [securestring]$pass,
        [Parameter(Mandatory,Position=5)]
        [string]$customer
    )

    Add-DynModule

    If ($user -and $customer -and $pass) {
        Write-Verbose "All arguments for authentication has been set"
        Write-Verbose "Trying to establish connection to DynECT"
        Connect-DynDnsSession -User $user -Customer $customer -Password $pass
    
        If (Test-DynDnsSession) {
            Write-Verbose "Successfully generated auth token to DynECT"
        } Else {
            Write-Warning "Token could not be generated, connection to DynECT has failed" 
            Return
        }

        If ($zone -and $RecordName -and $TxtValue) {
            Write-Verbose "All arguments for updating DNS has been set"
            Write-Verbose "Trying to add DNS record to DynECT"
            Add-DynDnsRecord -Zone $zone -Node $RecordName -DynDnsRecord (New-DynDnsRecord -Text $TxtValue) -Confirm:$false

            If (Get-DynDnsZoneChanges -Zone $zone) {
                Write-Verbose "DNS Zone has new changes"
            } Else {
                Write-Warning "DNS Zone do not have any new changes to publish"
            }
        } Else {
            Write-Warning "Missing arguments for updating DNS zone"
            Write-Warning "Following arguments are needed: `nzone `nRecordName `nTxtValue"
            Return
        }

    } Else {
        Write-Warning "Missing arguments for authentication"
        Write-Warning "Following arguments are needed: `nuser `ncustomer `npass"
        Return
    }

<#
    .SYNOPSIS
        Add a DNS TXT record to a DynECT hosted zone.

    .DESCRIPTION
        This plugin require PoShDynDnsApi powershell module.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER Zone
        The zone is the root domain e.g. example.com

    .PARAMETER user
        The user is the username that has permissions to DynECT API 

    .PARAMETER pass
        The pass is the password of the user that has permissions to DynECT API 

    .PARAMETER customer
        The customer is the DynECT customer registered name, this is needed to generate authentication token

    .EXAMPLE
        Add-DnsTxtDynECT '_acme-challenge.example.com' 'asdfqwer12345678' -Zone 'example.com' -user 'username' -pass (ConvertTo-SecureString -AsPlainText 'password' -Force) -customer 'customername'

    .EXAMPLE
        $seckey = Read-Host -Prompt 'Secret Key:' -AsSecureString
        Add-DnsTxtDynECT '_acme-challenge.example.com' 'asdfqwer12345678' -Zone 'example.com' -user 'username' -pass $seckey -customer 'customername

        Add a TXT record using an explicit Access Key and Secret key from Windows.
#>

}

function Remove-DnsTxtDynECT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$zone,
        [Parameter(Mandatory,Position=3)]
        [string]$user,
        [Parameter(Mandatory,Position=4)]
        [securestring]$pass,
        [Parameter(Mandatory,Position=5)]
        [string]$customer
    )
    
    If ($user -and $customer -and $pass) {
        Write-Verbose "All arguments for authentication has been set"
        Write-Verbose "Trying to establish connection to DynECT"
        Connect-DynDnsSession -User $user -Customer $customer -Password $pass
        
        If (Test-DynDnsSession) {
            Write-Verbose "DynECT session is alive"

            If ($zone -and $RecordName) {
                Write-Verbose "Trying to remove DNS record"
                $txtToRemove = Get-DynDnsRecord -Zone $zone -RecordType TXT -Node $RecordName 
        
                If ($txtToRemove) {
                    Write-Verbose "Record found, removing record: $txtToRemove"
                    Remove-DynDnsRecord -DynDnsRecord $txtToRemove -Confirm:$false

                    If (Get-DynDnsZoneChanges -Zone $zone) {
                        Write-Verbose "DNS Zone has new changes"
                    } Else {
                        Write-Warning "DNS Zone do not have any new changes to publish"
                    }
                } Else {
                    Write-Warning "No records to remove was found. Skipping removal"
                }
            } Else {
                Write-Warning "Missing arguments for removal of DNS Zone."
                Write-Warning "Make sure both 'zone' and 'RecordName' is set"
                Return
            }
        } Else {
            Write-Warning "DynECT session has been terminated. unable to remove record"
        }
    } Else {
        Write-Warning "Missing arguments for authentication"
        Write-Warning "Following arguments are needed: `nuser `ncustomer `npass"
        Return
    }

<#
    .SYNOPSIS
        Removes DNS record from DynECT hosted zone.

    .DESCRIPTION
        

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER Zone
        The zone is the root domain e.g. example.com

    .EXAMPLE
        Remove-DnsTxtDynECT '_acme-challenge.example.com' -Zone 'example.com' 
#>
}

function Save-DnsTxtDynECT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$zone,
        [Parameter(Mandatory,Position=1)]
        [string]$user,
        [Parameter(Mandatory,Position=2)]
        [securestring]$pass,
        [Parameter(Mandatory,Position=3)]
        [string]$customer
    )

    If ($zone) {
        Write-Verbose "All arguments has been set for publishing zone: $zone"
        Publish-DynDnsZoneChanges -Zone $zone -Force -Confirm:$false
        
        If (!(Get-DynDnsZoneChanges -Zone $zone)) {
            Write-Verbose "Zone: $zone has been published. no missing changes"
        } Else {
            Write-Warning "Zone: $zone still has missing changes to publish"
        }

        Write-Verbose "Disconnecting session to DynECT"
        Disconnect-DynDnsSession 

        If (Test-DynDnsSession) {
            Write-Warning "Unable to disconnect session to DynECT"
        } Else {
            Write-Verbose "Successfully disconnected to DynECT" 
        }
    }
<#
    .SYNOPSIS
        Publish DNS changes to DynECT hosted zone.

    .DESCRIPTION
        
    .PARAMETER Zone
        The zone is the root domain e.g. example.com

    .EXAMPLE
        Save-DnsTxtDynECT -Zone 'example.com' 
#>

}

Function Add-DynModule {
    $Module = Get-Module -ListAvailable -name "PoShDynDnsApi"

    If ($Module.Count -ge 1) {
        Write-Verbose "PoShDynDnsApi powershell module is present"
        Import-Module -Name PoShDynDnsApi
    } Else {
        Try {
            Write-Verbose "PoShDynDnsApi powershell module is missing, installing"
            Install-Module -Name PoShDynDnsApi -Scope CurrentUser
            Write-Verbose "Successfully installed PoShDynDnsApi module"
            Import-Module -Name "PoShDynDnsApi" 
        } Catch {
            Write-Warning "Module was unable to be installed"
            Return
        }
    }
}

############################
# Helper Functions
############################

# Add additional functions here if necessary.
# Make sure they're uniquely named and try to follow
# verb-noun naming guidelines.
# https://msdn.microsoft.com/en-us/library/ms714428
