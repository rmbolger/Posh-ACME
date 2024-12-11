function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Looking for Zonename in $($RecordName)..."
    $EuroDNSResellerZone = Find-EuroDNSResellerZone -EuroDNSReseller_zone $RecordName -EuroDNSReseller_Creds $EuroDNSReseller_Creds
    
    If ($EuroDNSResellerZone) {

        # Getting DNS records
        try {

            

            # Checking to see if there is any data to work with. Don't want to overwrite in case we make multiple changes
            Write-Debug "Checking if EuroDNsResellerObject has data..."
            If ( -not ($script:EuroDNSResellerObject)) {
                
                Write-Verbose "Trying to get data from EuroDNSReseller..."
                $script:EuroDNSResellerObject = Get-EuroDNSResellerZone -EuroDNSReseller_Domain $EuroDNSResellerZone -EuroDNSReseller_Creds $EuroDNSReseller_Creds -ErrorAction Stop | ConvertFrom-Json
                

            } 

            Write-Verbose "Data Found. Number of Records: $($script:EuroDNSResellerObject.records.count)"

            

            # assumes $EuroDNSResellerZone contains the zone name containing the record
            $recShort = ($RecordName -ireplace [regex]::Escape($EuroDNSResellerZone), [string]::Empty).TrimEnd('.')

            if ($recShort -eq [string]::Empty) {
                $recShort = '@'
            }

            Write-debug "recShort is: $($recShort)"
            
            # Don't want to add an identical record/value. Check for existing records:
            If (($recShort -in $script:EuroDNSResellerObject.records.host) -and ($TxtValue -in $script:EuroDNSResellerObject.records.rdata)){

                
                Write-Verbose "Record exists already in EuroDNSReseller - Skipping..."
                Write-Verbose "Records in object: $($script:EuroDNSResellerObject.records.host -join ",")"
                Write-Verbose "In Zone: $($script:EuroDNSResellerObject)"

            } else {

                # Create the new record (No ID needed)
                # For new records It expects all of these fields
                $EuroDNSResellernewRecord = [pscustomobject]@{
                    type      = "TXT"
                    host      = $recShort
                    ttl       = 3600
                    rdata     = $TxtValue
                    updated   = $false
                    locked    = $false
                    isDynDNS  = $null
                    proxy     = $null
                }

                # recreate the object with the new record
                $script:EuroDNSResellerObject.records += @($EuroDNSResellernewRecord)
                Write-Verbose "New object added - Number of Records now: $($script:EuroDNSResellerObject.records.count)"


            }

            
        }
        catch {
            throw
        }

    } else {
        Write-Verbose "...No available domain zone found..."
    }
    

    <#
    .SYNOPSIS
        Add a DNS TXT record to EuroDNSReseller

    .DESCRIPTION
        Description for EuroDNSReseller

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

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
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Checking for zonename
    Write-Verbose "Looking for Zonename in $($RecordName)..."
    $EuroDNSResellerZone = Find-EuroDNSResellerZone -EuroDNSReseller_zone $RecordName -EuroDNSReseller_Creds $EuroDNSReseller_Creds
    If ($EuroDNSResellerZone) {

        # Getting DNS records
        try {

            # Checking to see if there is any data to work with. Don't want to overwrite in case we make multiple changes
            If ( -not ($script:EuroDNSResellerObject)) { 

                Write-Verbose "Trying to get data from EuroDNSReseller..."
                $script:EuroDNSResellerObject = Get-EuroDNSResellerZone -EuroDNSReseller_Domain $EuroDNSResellerZone -EuroDNSReseller_Creds $EuroDNSReseller_Creds -ErrorAction Stop | ConvertFrom-Json

            }
                       
            Write-Verbose "Data Found. Number of Records: $($script:EuroDNSResellerObject.records.count)"

            
            
            # assumes $EuroDNSResellerZone contains the zone name containing the record
            $recShort = ($RecordName -ireplace [regex]::Escape($EuroDNSResellerZone), [string]::Empty).TrimEnd('.')

            if ($recShort -eq [string]::Empty) {
                $recShort = '@'
            }

            # Doing a check to make sure there is something to remove
            Write-Verbose "Searching for records to remove..."
            If($script:EuroDNSResellerObject.records | Where-Object {($_.host -eq $recShort -and $_.rdata -eq $TxtValue)}) {

                # Seaching for record to remove - Doing a not search since we only want to remove a specific record and keep all else.
                $script:EuroDNSResellerObject.records = $script:EuroDNSResellerObject.records | Where-Object {!($_.host -eq $recShort -and $_.rdata -eq $TxtValue)}


            } else {

                Write-Verbose "Could not find any records matching. Nothing will be removed."

            }

            Write-Verbose "Number of Records now: $($script:EuroDNSResellerObject.records.count)"
            
        }
        catch {

            throw

        }

    } else {

        Write-Verbose "...No available domain zone found..."

    }
    


    <#
    .SYNOPSIS
        Remove a DNS TXT record from EuroDNS

    .DESCRIPTION
        Description for EuroDNSReseller

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    
    # We want to confirm our changes before saving them
    # Checking to see if we get a pass from EuroDNSReseller with our new records. 
    # If our object is not exactly in the format expected, then it will fail validation
    # so we should skip the saving.
    $EuroDNSReseller_Confirm = $script:EuroDNSResellerObject | Confirm-EuroDNSReseller -EuroDNSReseller_Creds $EuroDNSReseller_Creds
    IF ($EuroDNSReseller_Confirm.report.isValid -eq $true) {

        Write-Verbose "EuroDNSReseller Validation completed succesfully.. Sending data to EuroDNSReseller"
        $script:EuroDNSResellerObject | Save-EuroDNSReseller -EuroDNSReseller_Creds $EuroDNSReseller_Creds
        Write-Debug "Cleaning EURODNSResellerObject.. "
        $script:EuroDNSResellerObject = $null

    } else {

        Write-Verbose "EuroDNSReseller does NOT accept our object - Something is wrong with our data and it's not passing the confirm check. Try debug"
        Write-Debug "Records in Data we tried to send: $($script:EuroDNSResellerObject.records)"
        throw "Validation failed - The data sent to EuroDNSReseller was not approved"
    }

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to EuroDNSReseller

    .DESCRIPTION
        Description for EuroDNSReseller

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications.
    #>
}

############################
# Helper Functions
############################
# API documentation: https://docapi.EuroDNS.com/

# Creates the header with our API ID/Key
function Connect-EuroDNSReseller {
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds
        
    )
    
    process {
        
        $EuroDNSReseller_headers =  @{
            'Content-Type' = 'application/json'
            'X-APP-ID' = $EuroDNSReseller_Creds.UserName
            'X-API-KEY' = $EuroDNSReseller_Creds.GetNetworkCredential().Password
        }
        
        $EuroDNSReseller_headers
    }
}

# Returns all records for a specific zone
function Get-EuroDNSResellerZone {
    param (
        [Parameter(Mandatory)]
        [string]
        $EuroDNSReseller_Domain,

        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds
    )

    Process {
        $URL = 'https://rest-api.EuroDNS.com/dns-zones/' + $EuroDNSReseller_Domain

        try {

            $(Invoke-WebRequest -uri $url -headers $(Connect-EuroDNSReseller $EuroDNSReseller_Creds) -erroraction Stop @script:UseBasic).content
            
        }
        catch {
            throw
        }
        
    }
    
}

# We need to validate data before saving it.
function Confirm-EuroDNSReseller {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [psobject]
        $EuroDNSReseller_Data,

        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds
    )
    process {
        $domain = $($EuroDNSReseller_Data.name)
        $URL = "https://rest-api.EuroDNS.com/dns-zones/$($domain)/check"
        
        try {
            $(Invoke-WebRequest $url -headers $(Connect-EuroDNSReseller $EuroDNSReseller_Creds) -Body ($EuroDNSReseller_Data | ConvertTo-Json -Depth 10) -Method Post -erroraction Stop @script:UseBasic).content | ConvertFrom-Json -Depth 10
        }
        catch {

            throw
        }
    }
}
# Saves the changes to EuroDNS
function Save-EuroDNSReseller {
    [CmdletBinding()]
    param (

        [Parameter(ValueFromPipeline)]
        [psobject]
        $EuroDNSReseller_Data,

        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds
        
    )
    
        
    process {

        $domain = $($EuroDNSReseller_Data.name)
        $URL = "https://rest-api.EuroDNS.com/dns-zones/$($domain)"

        try {

            Invoke-WebRequest $url -headers $(Connect-EuroDNSReseller $EuroDNSReseller_Creds) -Body ($EuroDNSReseller_Data | ConvertTo-Json -Depth 10) -Method Put -erroraction Stop @script:UseBasic | Out-Null
            
        }
        catch {
            throw
        }

    }
    
}

# Looking through each subdomain until we find one that works.
function Find-EuroDNSResellerZone {
    param (
        [Parameter(Mandatory)]
        [string]
        $EuroDNSReseller_zone,
        
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds
        
        
    )

    Process {
        
        
        $zonestring = $EuroDNSReseller_zone
        # Creating a counter based on amount of subdomains.
        $mycount = ($EuroDNSReseller_zone).split(".")

        # Testing the zone string from left to right, removing a subdomain for each failed call. Added a few checks in case of
        ## - Domain doesn't exists
        ## - We hit a Top-Level domain (like com or uk.org) (The API "Available Domains" will return 200 on this, but you can't really make changes on this level)
        Write-Verbose "Number of domains to test: $($mycount.count)"
        1..$mycount.count | ForEach-Object {

            
            # We want to return nothing if a useable domain cannot be found.
            If ($_ -eq $mycount.Count -and $skipcounter -eq $false ) {

                $zonestring = $null


            } else {
                
                
                # Looking thorugh each domain starting from the left most side.
                If ($call.StatusCode -eq '200') {
            
                    Write-Verbose "Found the available domain / zonename - $zonestring"
                    $Getoutofloop = $true
                    $Call = 0

                } else {

                    If (!($Getoutofloop -eq $true)) {
                        try {
            
                            $body = @{
                    
                                domainNames = @($zonestring)
                            }
                    
                            Write-Verbose "$($_).. $zonestring - testing to see if this domain is available"
                            $call = Invoke-WebRequest  'https://rest-api.eurodns.com/das/available-domain-names' -Body $($body | ConvertTo-Json) -Headers $(Connect-EuroDNSReseller $EuroDNSReseller_Creds) -Method Post -erroraction Stop @script:UseBasic
                    
                            
                        }
                        catch {
                    
                            Write-Verbose "$zonestring - Domain not available.. Trying next"
                            
                        }
                
                        # Want to stop looking as soons as we find the first available domain one
                        If ($call.StatusCode -eq '200') {

                            $skipcounter = $true

                        } else {
                            
                            # Removing each sub domain one at a time.
                            $index = $zonestring.IndexOf('.')
                            $zonestring = $zonestring.Substring($index + 1)
                            $zonestring = $zonestring

                        }
                    }
                }
            }
        }

        $zonestring
        
    }
    
}
