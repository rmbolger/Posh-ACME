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

    # Finding our zonename (Works great for simple domains like mydomain.com. Will fail on mydomain.co.uk or mydomain.com.fr)
    Write-Verbose "Looking for Zonename in $($RecordName)..."
    $EuroDNSResellerZone = $RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$2'
    Write-Verbose "Found: $($EuroDNSResellerZone)"

    # Test to see if we are working with a TLD (Top-Level Domain). This fixes the problem above where the logic will return co.uk on mydomain.co.uk
    If ($(Get-EuroDNSResellerTLD -EuroDNSReseller_tld $($EuroDNSResellerZone) -EuroDNSReseller_Creds $EuroDNSReseller_Creds).StatusCode -eq "200") {
    
        Write-Verbose "Found the TLD - Fixing the Zonename"
        ## we are looking for the most top level domain possible. This ugly code will find the most top level domain.
        $EuroDNSResellerTLDCheck = ((($RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$1').TrimEnd(".")).split(".")).count
        $EuroDNSResellerZone = ((($RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$1').TrimEnd(".")).split("."))[$EuroDNSResellerTLDCheck - 1] + "." + $EuroDNSResellerZone
        Write-Verbose "After fix, the ZoneName is: $EuroDNSResellerZone"

    } else {
    
        Write-Verbose "Not an TLD"
    
    }
    
          
    # Getting DNS records
    try {

        # Checking to see if there is any data to work with. Don't want to overwrite in case we make multiple changes
        If ( -not ($script:EuroDNSResellerObject)) {

            Write-Verbose "Trying to get data from EuroDNSReseller..."
            $script:EuroDNSResellerObject = Get-EuroDNSResellerZone -EuroDNSReseller_Domain $EuroDNSResellerZone -EuroDNSReseller_Creds $EuroDNSReseller_Creds -ErrorAction Stop | ConvertFrom-Json
            Write-Verbose "Data Found. Number of Records: $($script:EuroDNSResellerObject.records.count)"

        } 
        
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
    $EuroDNSResellerZone = $RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$2'
    Write-Verbose "Found: $($EuroDNSResellerZone)"
          
    # Getting DNS records
    try {

        # Test to see if we are working with a TLD (Top-Level Domain). This fixes the problem above where the logic will return co.uk on mydomain.co.uk
        If ($(Get-EuroDNSResellerTLD -EuroDNSReseller_tld $($EuroDNSResellerZone) -EuroDNSReseller_Creds $EuroDNSReseller_Creds).StatusCode -eq "200") {
        
            Write-Verbose "Found the TLD - Fixing the Zonename"
            ## we are looking for the most top level domain possible. This ugly code will find the most top level domain.
            $EuroDNSResellerTLDCheck = ((($RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$1').TrimEnd(".")).split(".")).count
            $EuroDNSResellerZone = ((($RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$1').TrimEnd(".")).split("."))[$EuroDNSResellerTLDCheck - 1] + "." + $EuroDNSResellerZone
            Write-Verbose "After fix, the ZoneName is: $EuroDNSResellerZone"

        } else {
        
            Write-Verbose "Not an TLD"
        
        }

        # Checking to see if there is any data to work with. Don't want to overwrite in case we make multiple changes
        If ( -not ($script:EuroDNSResellerObject)) { 

            Write-Verbose "Trying to get data from EuroDNSReseller..."
            $script:EuroDNSResellerObject = Get-EuroDNSResellerZone -EuroDNSReseller_Domain $EuroDNSResellerZone -EuroDNSReseller_Creds $EuroDNSReseller_Creds -ErrorAction Stop | ConvertFrom-Json
            Write-Verbose "Data Found. Number of Records: $($script:EuroDNSResellerObject.records.count)"

        }
        
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
# Saves the changes to EuroDNSReseller
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

function Get-EuroDNSResellerTLD {
    param (
        [Parameter(Mandatory)]
        [string]
        $EuroDNSReseller_tld,
        
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNSReseller_Creds
        
        
    )

    Process {
        $URL = 'https://rest-api.EuroDNS.com/tlds?tld-name=' + $EuroDNSReseller_tld

        try {

            Write-Verbose "attepmting to find TLD: $($EuroDNSReseller_tld) "
            Write-Verbose "Following URL: $($URL) "

            Invoke-WebRequest -uri $url -headers $(Connect-EuroDNSReseller $EuroDNSReseller_Creds) -erroraction Stop @script:UseBasic
            
        }
        catch {
            throw
        }
        
    }
    
}