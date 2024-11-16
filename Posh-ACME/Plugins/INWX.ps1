function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$INWXUsername,
        [Parameter(Mandatory,Position=3)]
        [securestring]$INWXPassword,
        [Parameter(Position=4)]
        [AllowNull()]
        [securestring]$INWXSharedSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # login
    Connect-Inwx $INWXUsername $INWXPassword $INWXSharedSecret

    # set communication endpoint
    # production system at: https://api.domrobot.com
    # test system at: https://api.ote.domrobot.com
    $apiRoot = "https://api.domrobot.com/jsonrpc/"

    # get DNS zone (main domain) and name (sub domain) belonging to the record (assumes
    # $zoneName contains the zone name containing the record)
    $zoneName = Find-InwxZone $RecordName
    $recShort = $RecordName.Remove($RecordName.ToLower().LastIndexOf($zoneName.ToLower().TrimEnd(".")), $zoneName.TrimEnd(".").Length).TrimEnd(".");
    Write-Debug "RecordName: $RecordName"
    Write-Debug "zoneName: $zoneName"
    Write-Debug "recShort: $recShort"

    # check if the record exists
    # https://www.inwx.de/en/help/apidoc/f/ch02s15.html#nameserver.info
    $reqParams = @{}
    $reqParams.Uri = $apiRoot
    $reqParams.Method = "POST"
    $reqParams.ContentType = "application/json"
    $reqParams.WebSession = $INWXSession
    $reqParams.Body = @{
        "jsonrpc" = "2.0";
        "id" = [guid]::NewGuid()
        "method" = "nameserver.info";
        "params" = @{
            "domain" = $zoneName;
            "type" = "TXT";
            "name" = $recShort;
        };
    } | ConvertTo-Json

    $response = $False
    $responseContent = $False
    $recordIds = $False
    try {
        Write-Verbose "Checking for $RecordName record(s)."
        Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
        $response = Invoke-WebRequest @reqParams @script:UseBasic
    } catch {
        throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
    }
    if ($response -eq $False -or
        $response.StatusCode -ne 200) {
        throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
    } else {
        $responseContent = $response.Content | ConvertFrom-Json
    }
    Write-Debug "Received content:`n$($response.Content)"

    switch ($responseContent.code) {
        # 1000: Command completed successfully
        # 2302: Object exists
        {($PSItem -eq 1000 -or
          $PSItem -eq 2302)} {
            Write-Debug "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) was successful"
            if ($responseContent.resData.count -gt 0 -and
                $responseContent.resData.record.id) {
                $recordIds = $responseContent.resData.record.id
                if (-not $recordIds -is [array]) {
                    $recordIds = @($recordIds)
                }
                Write-Debug "Found record(s) with ID(s) $recordIds."
            }
        }
        # unexpected
        default {
            throw "Unexpected response from INWX (code: $($responseContent.code)). The plugin might need an update (Add-DnsTxt)."
        }
    }
    Remove-Variable "reqParams", "response", "responseContent"

    if ($recordIds) {
        foreach ($recordId in $recordIds) {
            Write-Verbose "DNS record is already existing, going to update it."
            # update record
            # https://www.inwx.de/en/help/apidoc/f/ch02s15.html#nameserver.updateRecord
            $reqParams = @{}
            $reqParams.Uri = $apiRoot
            $reqParams.Method = "POST"
            $reqParams.ContentType = "application/json"
            $reqParams.WebSession = $INWXSession
            $reqParams.Body = @{
                "jsonrpc" = "2.0";
                "id" = [guid]::NewGuid()
                "method" = "nameserver.updateRecord";
                "params" = @{
                    "id" = $recordId;
                    "type" = "TXT";
                    "content" = $TxtValue;
                    "ttl" = 300;
                };
            } | ConvertTo-Json

            $response = $False
            $responseContent = $False
            try {
                Write-Verbose "Adding record $RecordName with value $TxtValue."
                Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
                $response = Invoke-WebRequest @reqParams @script:UseBasic
            } catch {
                throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
            }
            if ($response -eq $False -or
                $response.StatusCode -ne 200) {
                throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
            } else {
                $responseContent = $response.Content | ConvertFrom-Json
            }
            Write-Debug "Received content:`n$($response.Content)"
            # 1000: Command completed successfully
            if ($responseContent.code -eq 1000) {
                Write-Verbose "Updating the record was successful."
            } else {
                throw "Updating the record failed (code: $($responseContent.code))."
            }
            Remove-Variable "reqParams", "response", "responseContent"
        }

    } else {

        Write-Verbose "DNS record does not exist, going to create it."
        # create record
        # https://www.inwx.de/en/help/apidoc/f/ch02s15.html#nameserver.createRecord
        $reqParams = @{}
        $reqParams.Uri = $apiRoot
        $reqParams.Method = "POST"
        $reqParams.ContentType = "application/json"
        $reqParams.WebSession = $INWXSession
        $reqParams.Body = @{
            "jsonrpc" = "2.0";
            "id" = [guid]::NewGuid()
            "method" = "nameserver.createRecord";
            "params" = @{
                "domain" = $zoneName;
                "type" = "TXT";
                "name" = $recShort;
                "content" = $TxtValue;
                "ttl" = 300;
            };
        } | ConvertTo-Json

        $response = $False
        $responseContent = $False
        try {
            Write-Verbose "Adding record $RecordName with value $TxtValue."
            Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
            $response = Invoke-WebRequest @reqParams @script:UseBasic
        } catch {
            throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
        }
        if ($response -eq $False -or
            $response.StatusCode -ne 200) {
            throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
        } else {
            $responseContent = $response.Content | ConvertFrom-Json
        }
        Write-Debug "Received content:`n$($response.Content)"
        # 1000: Command completed successfully
        if ($responseContent.code -eq 1000) {
            Write-Verbose "Adding the record was successful."
            if ($responseContent.resData.id -gt 0) {
                Write-Debug "Created record with ID $($responseContent.resData.id)."
            }
        } else {
            throw "Adding the record failed (code: $($responseContent.code))."
        }
        Remove-Variable "reqParams", "response", "responseContent"
    }
    Remove-Variable "recordIds"

    <#
    .SYNOPSIS
        Add a DNS TXT record to INWX.

    .DESCRIPTION
        Uses the INWX DNS API to add or update a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER INWXUsername
        The INWX Username to access the API.

    .PARAMETER INWXPassword
        The password belonging to the username provided via -INWXUsername.

    .PARAMETER INWXSharedSecret
        If your account is secured by mobile TAN ("2FA", "two-factor authentication"), you must define the shared secret (usually presented below the QR code during mobile TAN setup) to enable this function to generate OTP codes. The shared secret is NOT not the 6-digit code you need to enter when logging in. If you are not using 2FA, leave this parameter undefined or set it to $null..

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $password = Read-Host 'API Secret' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -INWXUsername 'xxxxxx' -INWXPassword $password

        Adds or updates the specified TXT record with the specified value.
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
        [string]$INWXUsername,
        [Parameter(Mandatory,Position=3)]
        [securestring]$INWXPassword,
        [Parameter(Position=4)]
        [securestring]$INWXSharedSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # login
    Connect-Inwx $INWXUsername $INWXPassword $INWXSharedSecret

    # set communication endpoint
    # production system at: https://api.domrobot.com
    # test system at: https://api.ote.domrobot.com
    $apiRoot = "https://api.domrobot.com/jsonrpc/"

    # get DNS zone (main domain) and name (sub domain) belonging to the record (assumes
    # $zoneName contains the zone name containing the record)
    $zoneName = Find-InwxZone $RecordName
    $recShort = $RecordName.Remove($RecordName.ToLower().LastIndexOf($zoneName.ToLower().TrimEnd(".")), $zoneName.TrimEnd(".").Length).TrimEnd(".");
    Write-Debug "RecordName: $RecordName"
    Write-Debug "zoneName: $zoneName"
    Write-Debug "recShort: $recShort"

    # check if the record exists
    # https://www.inwx.de/en/help/apidoc/f/ch02s15.html#nameserver.info
    $reqParams = @{}
    $reqParams.Uri = $apiRoot
    $reqParams.Method = "POST"
    $reqParams.ContentType = "application/json"
    $reqParams.WebSession = $INWXSession
    $reqParams.Body = @{
        "jsonrpc" = "2.0";
        "id" = [guid]::NewGuid()
        "method" = "nameserver.info";
        "params" = @{
            "domain" = $zoneName;
            "type" = "TXT";
            "name" = $recShort;
            "content" = $TxtValue;
        };
    } | ConvertTo-Json

    $response = $False
    $responseContent = $False
    $recordIds = $False
    try {
        Write-Verbose "Checking for $RecordName record(s) with value $TxtValue."
        Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
        $response = Invoke-WebRequest @reqParams @script:UseBasic
    } catch {
        throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
    }
    if ($response -eq $False -or
        $response.StatusCode -ne 200) {
        throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
    } else {
        $responseContent = $response.Content | ConvertFrom-Json
    }
    Write-Debug "Received content:`n$($response.Content)"

    switch ($responseContent.code) {
        # 1000: Command completed successfully
        # 2302: Object exists
        {($PSItem -eq 1000 -or
          $PSItem -eq 2302)} {
            Write-Debug "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) was successful"
            if ($responseContent.resData.count -gt 0 -and
                $responseContent.resData.record.id) {
                $recordIds = $responseContent.resData.record.id
                if (-not $recordIds -is [array]) {
                    $recordIds = @($recordIds)
                }
                Write-Debug "Found record(s) with ID(s) $recordIds."
            }
        }
        # unexpected
        default {
            throw "Unexpected response from INWX (code: $($responseContent.code)). The plugin might need an update (Remove-DnsTxt)."
        }
    }
    Remove-Variable "reqParams", "response", "responseContent"

    if ($recordIds) {
        foreach ($recordId in $recordIds) {
            Write-Verbose "DNS record is existing, going to delete it."
            # delete record
            # https://www.inwx.de/en/help/apidoc/f/ch02s15.html#nameserver.deleteRecord
            $reqParams = @{}
            $reqParams.Uri = $apiRoot
            $reqParams.Method = "POST"
            $reqParams.ContentType = "application/json"
            $reqParams.WebSession = $INWXSession
            $reqParams.Body = @{
                "jsonrpc" = "2.0";
                "id" = [guid]::NewGuid()
                "method" = "nameserver.deleteRecord";
                "params" = @{
                    "id" = $recordId;
                };
            } | ConvertTo-Json

            $response = $False
            $responseContent = $False
            try {
                Write-Verbose "Deleting record $RecordName with value $TxtValue."
                Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
                $response = Invoke-WebRequest @reqParams @script:UseBasic
            } catch {
                throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
            }
            if ($response -eq $False -or
                $response.StatusCode -ne 200) {
                throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
            } else {
                $responseContent = $response.Content | ConvertFrom-Json
            }
            Write-Debug "Received content:`n$($response.Content)"
            # 1000: Command completed successfully
            if ($responseContent.code -eq 1000) {
                Write-Verbose "Deleting the record was successful."
            } else {
                throw "Deleting the record failed (code: $($responseContent.code))."
            }
            Remove-Variable "reqParams", "response", "responseContent"
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }
    Remove-Variable "recordIds"

    <#
    .SYNOPSIS
        Remove a DNS TXT record from INWX.

    .DESCRIPTION
        Uses the INWX DNS API to remove a DNS TXT record with a certain value.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER INWXUsername
        The INWX Username to access the API.

    .PARAMETER INWXPassword
        The password belonging to the username provided via -INWXUsername.

    .PARAMETER INWXSharedSecret
        If your account is secured by mobile TAN ("2FA", "two-factor authentication"), you must define the shared secret (usually presented below the QR code during mobile TAN setup) to enable this function to generate OTP codes. The shared secret is NOT not the 6-digit code you need to enter when logging in. If you are not using 2FA, leave this parameter undefined or set it to $null..

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
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # set communication endpoint
    # production system at: https://api.domrobot.com
    # test system at: https://api.ote.domrobot.com
    $apiRoot = "https://api.domrobot.com/jsonrpc/"

    # There is currently no additional work to be done to save
    # or finalize changes performed by Add/Remove functions.

    # let's logout (best effort)
    # https://www.inwx.de/en/help/apidoc/f/ch02.html#account.logout
    $reqParams = @{}
    $reqParams.Uri = $apiRoot
    $reqParams.Method = "POST"
    $reqParams.ContentType = "application/json"
    $reqParams.WebSession = $INWXSession
    $reqParams.Body = @{
        "jsonrpc" = "2.0";
        "id" = [guid]::NewGuid()
        "method" = "account.logout";
    } | ConvertTo-Json
    $response = $False
    $responseContent = $False
    try {
        Write-Verbose "Starting INWX logout to end the session (best-effort)."
        Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
        $response = Invoke-WebRequest @reqParams @script:UseBasic
    } catch {
        Write-Debug "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
    }
    if ($response -eq $False -or
        $response.StatusCode -ne 200) {
        Write-Debug "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
    } else {
        $responseContent = $response.Content | ConvertFrom-Json
    }
    Write-Debug "Received content:`n$($response.Content)"
    # 1000: Command completed successfully
    # 1500: Command completed successfully; ending session
    if ($responseContent.code -eq 1000 -or
        $responseContent.code -eq 1500) {
        Write-Verbose "Logout was successful."
    } else {
        Write-Debug "Logout failed (code: $($responseContent.code))."
    }
    Remove-Variable "reqParams", "response", "responseContent"

    # invalidate saved session data
    $script:INWXSession = $False

    <#
    .SYNOPSIS
        Commits changes to pending DNS TXT record modifications to INWX and closes an existing RPC session by logging out.

    .DESCRIPTION
        This function is currently a dummy which just does a clean logout as INWX does not support a 'finalize' or 'commit' workflow.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications
        and closes an existing RPC session by logging out.
    #>
}


############################
# Helper Functions
############################

# API Docs at https://www.inwx.de/en/help/apidoc
# Result codes at https://www.inwx.de/en/help/apidoc/f/ch04.html
#
# There is also an OT&E test system. It provides the usual WebUI and API using a test database.
# On the OTE system no actions will be charged. So one can test how to register domains etc..
# An OT&E account can be created at https://www.ote.inwx.de/en/customer/signup

function Connect-Inwx {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$INWXUsername,
        [Parameter(Mandatory,Position=1)]
        [securestring]$INWXPassword,
        [Parameter(Position=2)]
        [AllowNull()]
        [securestring]$INWXSharedSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # no need to log in again; an authenticated session already exists
    if ((Test-Path 'variable:script:INWXSession') -and ($script:INWXSession)) {
        Write-Debug "Login not needed, using cached INWX session."
        return
    }

    # get password as plaintext
    $INWXPasswordInsecure = [pscredential]::new('a',$INWXPassword).GetNetworkCredential().Password

    # set communication endpoint
    # production system at: https://api.domrobot.com
    # test system at: https://api.ote.domrobot.com
    $apiRoot = "https://api.domrobot.com/jsonrpc/"

    Write-Debug "Starting INWX login to get a session."
    # login
    # https://www.inwx.com/en/help/apidoc/f/ch02.html#account.login
    $reqParams = @{}
    $reqParams.Uri = $apiRoot
    $reqParams.Method = "POST"
    $reqParams.ContentType = "application/json"
    $reqParams.SessionVariable = "INWXSession"
    $reqParams.Body = @{
        "jsonrpc" = "2.0";
        "id" = [guid]::NewGuid()
        "method" = "account.login";
        "params" = @{
            "user" = $INWXUsername;
            "pass" = $INWXPasswordInsecure;
        };
    } | ConvertTo-Json

    $response = $False
    $responseContent = $False
    $2faActive = $False
    try {
        # commented out to prevent printing the credentials: Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
        $response = Invoke-WebRequest @reqParams @script:UseBasic
    } catch {
        throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)"
    }
    if ($response -eq $False -or
        $response.StatusCode -ne 200) {
        throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
    } else {
        $responseContent = $response.Content | ConvertFrom-Json
    }
    Write-Debug "Received content:`n$($response.Content)"

    switch ($responseContent.code) {
        # 1000: Command completed successfully
        1000 {
            Write-Verbose "INWX login was successful."
            if ($responseContent.resData.tfa -eq "GOOGLE-AUTH") {
                Write-Verbose "2FA (Mobile TAN) is active, account needs unlocking."
                $2faActive = $True
            }
        }

        # 2200: Authentication error
        # 2400: Command failed
        {$PSItem -eq 2200 -or
         $PSItem -eq 2400} {
            throw "INWX login failed. Please check your credentials."
        }
        # unexpected
        default {
            throw "Unexpected response from INWX (code: $($responseContent.code)). The plugin might need an update (Connect-Inwx)."
        }
    }
    Remove-Variable "reqParams", "response", "responseContent"

    if ($2faActive) {

        # generate needed OTP
        if ($INWXSharedSecret) {
            $Otp = Get-InwXOtp $INWXSharedSecret
        } else {
            throw "Mobile TAN (2FA) is active for the $INWXUsername account. Please provide the INWXSharedSecret plugin parameter or disable 2FA for the account."
        }

        # unlock account
        # https://www.inwx.de/en/help/apidoc/f/ch02.html#account.unlock
        $reqParams = @{}
        $reqParams.Uri = $apiRoot
        $reqParams.Method = "POST"
        $reqParams.ContentType = "application/json"
        $reqParams.WebSession = $INWXSession
        $reqParams.Body = @{
            "jsonrpc" = "2.0";
            "id" = [guid]::NewGuid()
            "method" = "account.unlock";
            "params" = @{
                "tan" = $Otp;
            };
        } | ConvertTo-Json

        $response = $False
        $responseContent = $False
        try {
            Write-Verbose "Deleting record $RecordName with value $TxtValue."
            Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
            $response = Invoke-WebRequest @reqParams @script:UseBasic
        } catch {
            throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
        }
        if ($response -eq $False -or
            $response.StatusCode -ne 200) {
            throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
        } else {
            $responseContent = $response.Content | ConvertFrom-Json
        }
        Write-Debug "Received content:`n$($response.Content)"
        # 1000: Command completed successfully
        if ($responseContent.code -eq 1000) {
            Write-Verbose "Unlocking the account was successful."
        } else {
            throw "Unlocking the account failed (code: $($responseContent.code))."
        }
        Remove-Variable "reqParams", "response", "responseContent"
    }

    # save the session variable for usage in all later calls
    $script:INWXSession = $INWXSession

    <#
    .SYNOPSIS
        Internal helper function to create a session ("login") to communicate with the INWX API.

    .PARAMETER INWXUsername
        The INWX Username to access the API.

    .PARAMETER INWXPassword
        The password associated with the username provided via -INWXUsername.

    .PARAMETER INWXSharedSecret
        If your account is secured by mobile TAN ("2FA", "two-factor authentication"), you must define the shared secret (usually presented below the QR code during mobile TAN setup) to enable this function to generate OTP codes. The shared secret is NOT not the 6-digit code you need to enter when logging in. If you are not using 2FA, leave this parameter undefined or set it to $null..

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}


function Find-InwxZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!(Test-Path 'variable:script:INWXRecordZones')) {
        $script:INWXRecordZones = @{}
    }

    # check for the record in the cache
    if ($script:INWXRecordZones.ContainsKey($RecordName)) {
        return $script:INWXRecordZones.$RecordName
    }

    # set communication endpoint
    # production system at: https://api.domrobot.com
    # test system at: https://api.ote.domrobot.com
    $apiRoot = "https://api.domrobot.com/jsonrpc/"

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
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

        # check if the part of the domain is the zone
        # https://www.inwx.de/en/help/apidoc/f/ch02s15.html#nameserver.info
        $reqParams = @{}
        $reqParams.Uri = $apiRoot
        $reqParams.Method = "POST"
        $reqParams.ContentType = "application/json"
        $reqParams.WebSession = $INWXSession
        $reqParams.Body = @{
            "jsonrpc" = "2.0";
            "id" = [guid]::NewGuid()
            "method" = "nameserver.info";
            "params" = @{
                "domain" = $zoneTest;
            };
        } | ConvertTo-Json

        $response = $False
        $responseContent = $False
        try {
            Write-Verbose "Checking if $zoneTest is the zone holding the records."
            Write-Debug "$($reqParams.Method) $apiRoot`n$($reqParams.Body)"
            $response = Invoke-WebRequest @reqParams @script:UseBasic
        } catch {
            throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (unknown error)."
        }
        if ($response -eq $False -or
            $response.StatusCode -ne 200) {
            throw "INWX method call $(($reqParams.Body | ConvertFrom-Json).method) failed (status code $($response.StatusCode))."
        } else {
            $responseContent = $response.Content | ConvertFrom-Json
        }
        Write-Debug "Received content:`n$($response.Content)"

        switch ($responseContent.code) {
            # 1000: Command completed successfully
            # 2302: Object exists
            {$PSItem -eq 1000 -or
             $PSItem -eq 2302} {
                Write-Verbose "$zoneTest seems to be the zone holding the records."
                $script:INWXRecordZones.$RecordName = $zoneTest
                return $zoneTest
                break
            }
            # 2303: Object does not exist
            2303 {
                Write-Debug "$zoneTest does not seem to be the zone holding the records, trying the next deeper match."
            }
            # unexpected
            default {
                throw "Unexpected response from INWX (code: $($responseContent.code)). The plugin might need an update (Find-InwxZone)."
            }
        }
        Remove-Variable "reqParams", "response", "responseContent"
    }

    throw "Unable to find zone matching $RecordName."

    <#
    .SYNOPSIS
        Internal helper function to figure out which zone $RecordName needs to be added to.

    .PARAMETER RecordName
        The DNS Resource Record of which to find the belonging DNS zone.
    #>
}

function Get-InwXOtp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [securestring]$SharedSecret,
        [Parameter(Position=1)]
        [int]$Length = 6,
        [Parameter(Position=2)]
        [int]$Window = 30
    )

    # get shared secret as plaintext
    $SharedSecretInsecure = [pscredential]::new('a',$SharedSecret).GetNetworkCredential().Password
    $Epoch = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0

    # wait a bit if there are only a few seconds left in the current TOTP window
    $seconds = ([math]::floor((New-TimeSpan -Start $Epoch -End (Get-Date).ToUniversalTime()).TotalSeconds))
    $counter = [math]::floor($seconds / $Window)
    $nextTimeStep = ($counter + 1) * $Window
    if (($nextTimeStep - $seconds) -le 5) {
        Write-Debug "Current TOTP window is a bit tight, waiting a few seconds for the next one."
        Start-Sleep -Seconds 5
    }

    $hmac = New-Object -TypeName System.Security.Cryptography.HMACSHA1
    # padwith 'A' to a multiple of 8 characters and convert base32 to bytes
    $hmac.key = $SharedSecretInsecure.ToUpper().ToCharArray() + @("A") * ((8 - $SharedSecretInsecure.Length % 8) % 8) | `
        ForEach-Object { $q = 1L } {
            $q = ($q -shl 5) -bor [Math]::Max(0, "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".IndexOf($PSItem))
            if ($q -ge 0x10000000000L) {
                [BitConverter]::GetBytes($q)[4..0]
                $q = 1L
            }
        }

    $randHash = $hmac.ComputeHash([BitConverter]::GetBytes([long]([Math]::Floor((New-TimeSpan -Start ($Epoch) -End (Get-Date).ToUniversalTime()).TotalSeconds / $Window)))[7..0])

    $offset = $randhash[($randHash.Length-1)] -band 0xf
    $fullOtp = ($randhash[$offset] -band 0x7f) -shl 24
    $fullOtp += ($randHash[$offset + 1] -band 0xff) -shl 16
    $fullOtp += ($randHash[$offset + 2] -band 0xff) -shl 8
    $fullOtp += ($randHash[$offset + 3] -band 0xff)

    return [int](($fullOtp % [math]::pow(10, $Length)).ToString("0" * $Length))

    <#
    .SYNOPSIS
        Get Time-base One-Time Password Algorithm (RFC 6238)

    .PARAMETER SharedSecret
        The shared secret to use.

    .PARAMETER Length
        Length of the generated OTP. Defaults to 6.

    .PARAMETER Window
       Window of time in seconds within which the OTP code will be valid. Defaults to 30.

    .EXAMPLE
        Get-Otp (ConvertTo-SecureString -String "xxxxxxxx" -AsPlainText -Force)

        Generates a 6-digit OTP code based on the shared secret "xxxxxxxx"
    #>
}
