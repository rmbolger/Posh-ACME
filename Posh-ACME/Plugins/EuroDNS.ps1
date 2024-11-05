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
        $EuroDNS_Creds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Finding our zonename
    Write-Verbose "Looking for Zonename in $($RecordName)..."
    $EuroDNSZone = $RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$2'
    Write-Verbose "Found: $($EuroDNSZone)"
          
    # Getting DNS records
    try {

        # Checking to see if there is any data to work with. Don't want to overwrite in case we make multiple changes
        If ( -not ($script:EuroDNSObject)) {

            Write-Verbose "Trying to get data from eurodns..."
            $script:EuroDNSObject = Get-EuroDNSZone -EuroDNS_Domain $EuroDNSZone -EuroDNS_Creds $EuroDNS_Creds -ErrorAction Stop | ConvertFrom-Json
            Write-Verbose "Data Found. Number of Records: $($script:EuroDNSObject.records.count)"

        } 
        
        # assumes $EuroDNSZone contains the zone name containing the record
        $recShort = ($RecordName -ireplace [regex]::Escape($EuroDNSZone), [string]::Empty).TrimEnd('.')

        if ($recShort -eq [string]::Empty) {
            $recShort = '@'
        }

        Write-debug "recShort is: $($recShort)"
        
        # Don't want to add an identical record/value. Check for existing records:
        If (($recShort -in $script:EuroDNSObject.records.host) -and ($TxtValue -in $script:EuroDNSObject.records.rdata)){

            Write-Verbose "Record exists already in EuroDNS - Skipping..."

        } else {

            # Create the new record (No ID needed)
            # For new records It expects all of these fields
            $EuroDNSnewRecord = [pscustomobject]@{
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
            $script:EuroDNSObject.records += @($EuroDNSnewRecord)
            Write-Verbose "New object added - Number of Records now: $($script:EuroDNSObject.records.count)"


        }

        
    }
    catch {
        throw
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to EuroDNS

    .DESCRIPTION
        Description for EuroDNS

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
        $EuroDNS_Creds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Checking for zonename
    Write-Verbose "Looking for Zonename in $($RecordName)..."
    $EuroDNSZone = $RecordName -replace "^(.+\.)?([^.]+\.[^.]+)$", '$2'
    Write-Verbose "Found: $($EuroDNSZone)"
          
    # Getting DNS records
    try {

        # Checking to see if there is any data to work with. Don't want to overwrite in case we make multiple changes
        If ( -not ($script:EuroDNSObject)) { 

            Write-Verbose "Trying to get data from eurodns..."
            $script:EuroDNSObject = Get-EuroDNSZone -EuroDNS_Domain $EuroDNSZone -EuroDNS_Creds $EuroDNS_Creds -ErrorAction Stop | ConvertFrom-Json
            Write-Verbose "Data Found. Number of Records: $($script:EuroDNSObject.records.count)"

        }
        
        # assumes $EuroDNSZone contains the zone name containing the record
        $recShort = ($RecordName -ireplace [regex]::Escape($EuroDNSZone), [string]::Empty).TrimEnd('.')

        if ($recShort -eq [string]::Empty) {
            $recShort = '@'
        }

        # Doing a check to make sure there is something to remove
        Write-Verbose "Searching for records to remove..."
        If($script:EuroDNSObject.records | Where-Object {($_.host -eq $recShort -and $_.rdata -eq $TxtValue)}) {

            # Seaching for record to remove - Doing a not search since we only want to remove a specific record and keep all else.
            $script:EuroDNSObject.records = $script:EuroDNSObject.records | Where-Object {!($_.host -eq $recShort -and $_.rdata -eq $TxtValue)}


        } else {

            Write-Verbose "Could not find any records matching. Nothing will be removed."

        }

        Write-Verbose "Number of Records now: $($script:EuroDNSObject.records.count)"
        
    }
    catch {

        throw

    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from EuroDNS

    .DESCRIPTION
        Description for EuroDNS

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
        $EuroDNS_Creds,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    
    # We want to confirm our changes before saving them
    # Checking to see if we get a pass from eurodns with our new records. 
    # If our object is not exactly in the format expected, then it will fail validation
    # so we should skip the saving.
    $EuroDNS_Confirm = $script:EuroDNSObject | Confirm-EuroDNS -EuroDNS_Creds $EuroDNS_Creds
    IF ($EuroDNS_Confirm.report.isValid -eq $true) {

        Write-Verbose "EuroDNS Validation completed succesfully.. Sending data to EuroDNS"
        $script:EuroDNSObject | Save-EuroDNS -EuroDNS_Creds $EuroDNS_Creds

    } else {

        Write-Verbose "EuroDNS does NOT accept our object - Something is wrong with our data and it's not passing the confirm check. Try debug"
        Write-Debug "Records in Data we tried to send: $($script:EuroDNSObject.records)"
        throw "Validation failed - The data sent to EuroDNS was not approved"
    }

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to EuroDNS

    .DESCRIPTION
        Description for EuroDNS

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
# API documentation: https://docapi.eurodns.com/

# Creates the header with our API ID/Key
function Connect-EuroDNS {
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNS_Creds
        
    )
    
    process {
        $EuroDNS_headers =  @{
            'Content-Type' = 'application/json'
            'X-APP-ID' = $EuroDNS_Creds.UserName
            'X-API-KEY' = $EuroDNS_Creds.GetNetworkCredential().Password
        }
        
        $EuroDNS_headers
    }
}

# Returns all records for a specific zone
function Get-EuroDNSZone {
    param (
        [Parameter(Mandatory)]
        [string]
        $EuroDNS_Domain,

        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNS_Creds
    )

    Process {
        $URL = 'https://rest-api.eurodns.com/dns-zones/' + $EuroDNS_Domain

        try {

            $(Invoke-WebRequest -uri $url -headers $(Connect-EuroDNS $EuroDNS_Creds) -erroraction Stop @script:UseBasic).content
            
        }
        catch {
            throw
        }
        
    }
    
}

# We need to validate data before saving it.
function Confirm-EuroDNS {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [psobject]
        $EuroDNS_Data,

        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNS_Creds
    )
    process {
        $domain = $($EuroDNS_Data.name)
        $URL = "https://rest-api.eurodns.com/dns-zones/$($domain)/check"
        
        try {
            $(Invoke-WebRequest $url -headers $(Connect-EuroDNS $EuroDNS_Creds) -Body ($EuroDNS_Data | ConvertTo-Json -Depth 10) -Method Post -erroraction Stop @script:UseBasic).content | ConvertFrom-Json -Depth 10
        }
        catch {

            throw
        }
    }
}
# Saves the changes to EuroDNS
function Save-EuroDNS {
    [CmdletBinding()]
    param (

        [Parameter(ValueFromPipeline)]
        [psobject]
        $EuroDNS_Data,

        [Parameter(Mandatory)]
        [pscredential]
        $EuroDNS_Creds
        
    )
    
        
    process {

        $domain = $($EuroDNS_Data.name)
        $URL = "https://rest-api.eurodns.com/dns-zones/$($domain)"

        try {

            Invoke-WebRequest $url -headers $(Connect-EuroDNS $EuroDNS_Creds) -Body ($EuroDNS_Data | ConvertTo-Json -Depth 10) -Method Put -erroraction Stop @script:UseBasic | Out-Null
            
        }
        catch {
            throw
        }

    }
    
}
