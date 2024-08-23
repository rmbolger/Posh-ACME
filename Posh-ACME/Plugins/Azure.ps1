function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Credential')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AZSubscriptionId,
        [Parameter(ParameterSetName='Credential',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZTenantId,
        [Parameter(ParameterSetName='Credential',Mandatory)]
        [pscredential]$AZAppCred,
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZAppUsername,
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [string]$AZAppPasswordInsecure,
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [string]$AZCertThumbprint,
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZCertPfx,
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [securestring]$AZPfxPassSecure,
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [string]$AZPfxPass,
        [Parameter(ParameterSetName='Token',Mandatory)]
        [string]$AZAccessToken,
        [Parameter(ParameterSetName='IMDS',Mandatory)]
        [switch]$AZUseIMDS,
        [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
        [string]$AZEnvironment = 'AzureCloud',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-AZTenant @PSBoundParameters

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-AZZoneId $RecordName $AZSubscriptionId)) {
        throw "Unable to find Azure hosted zone for $RecordName"
    }

    # check for an existing record
    $rec = Get-AZTxtRecord $RecordName $zoneID

    # add (if necessary) the new TXT value to the list
    if ($rec.etag) {
        $txtVals = $rec.properties.TXTRecords
        if ($TxtValue -notin $txtVals.value) {
            $txtVals += @{value=@($TxtValue)}
        } else {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
            return
        }
    } else {
        $txtVals = @(@{value=@($TxtValue)})
    }

    # build the record update json
    $recBody = @{properties=@{TTL=10;TXTRecords=$txtVals}} | ConvertTo-Json -Compress -Depth 5

    Write-Verbose "Sending updated $($rec.name)"
    Write-Debug $recBody
    try {
        $response = Invoke-RestMethod "$($script:AZEnvironment.ResourceManagerUrl)$($rec.id)?api-version=2018-05-01" `
            -Method Put -Body $recBody -Headers $script:AZToken.AuthHeader `
            -ContentType 'application/json' @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }


    <#
    .SYNOPSIS
        Add a DNS TXT record to an Azure hosted zone.

    .DESCRIPTION
        Use an App Registration service principal to add a TXT record to an Azure DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AZSubscriptionId
        The Subscription ID of the Azure DNS zone. This can be found on the Properties page of the zone.

    .PARAMETER AZTenantId
        The Tenant or Directory ID of the Azure AD instance that controls access to your Azure DNS zone. This can be found on the Properties page of your Azure AD instance.

    .PARAMETER AZAppCred
        The username and password for an Azure AD user or service principal that has permissions to write TXT records in the specified zone. The username is the Application ID of the App Registration which can be found on its Properties page. The password is whatever was set at creation time.

    .PARAMETER AZAppUsername
        The username for an Azure AD user or service principal that has permissions to write TXT records in the specified zone. The username for a service principal is the Application ID of its associated App Registration which can be found on its properties page.

    .PARAMETER AZAppPasswordInsecure
        (DEPRECATED) The password for the principal specified by AZAppUsername.

    .PARAMETER AZCertThumbprint
        The thumbprint for a service principal's authentication certificate. This parameter should only be used from Windows. On non-Windows, please use AZCertPfx and AZPfxPassSecure parameters instead.

    .PARAMETER AZCertPfx
        The path to a service principal's PFX certificate file used for authentication.

    .PARAMETER AZPfxPassSecure
        The export password for the PFX file specified by AZCertPfx.

    .PARAMETER AZPfxPass
        (DEPRECATED) The export password for the PFX file specified by AZCertPfx.

    .PARAMETER AZAccessToken
        An existing Azure access token (JWT) to use for authorization when modifying TXT records. This is useful only for short lived instances or when the Azure authentication logic lives outside the module because access tokens are only valid for 1 hour.

    .PARAMETER AZUseIMDS
        If specified, the module will attempt to authenticate using the Azure Instance Metadata Service (IMDS). This will only work if the system is running within Azure and has been assigned a Managed Service Identity (MSI).

    .PARAMETER AZEnvironment
        The Azure cloud environment to use. Defaults to AzureCloud.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $azcred = Get-Credential
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZTenantId '22222222-2222-2222-2222-222222222222' -AZAppCred $azcred

        Adds a TXT record using expicit Azure tenant and credentials.

    .EXAMPLE
        $token = MyCustomLogin # external Azure auth
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZAccessToken $token

        Adds a TXT record using an existing Azure access token.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZUseIMDS

        Adds a TXT record from within Azure using a token from Azure Instance Metadata Service.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermadserviceprincipal

    .LINK
        https://docs.microsoft.com/en-us/azure/dns/dns-protect-zones-recordsets

    .LINK
        https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Credential')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AZSubscriptionId,
        [Parameter(ParameterSetName='Credential',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZTenantId,
        [Parameter(ParameterSetName='Credential',Mandatory)]
        [pscredential]$AZAppCred,
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZAppUsername,
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [string]$AZAppPasswordInsecure,
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [string]$AZCertThumbprint,
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZCertPfx,
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [securestring]$AZPfxPassSecure,
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [string]$AZPfxPass,
        [Parameter(ParameterSetName='Token',Mandatory)]
        [string]$AZAccessToken,
        [Parameter(ParameterSetName='IMDS',Mandatory)]
        [switch]$AZUseIMDS,
        [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
        [string]$AZEnvironment = 'AzureCloud',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-AZTenant @PSBoundParameters

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-AZZoneId $RecordName $AZSubscriptionId)) {
        throw "Unable to find Azure hosted zone for $RecordName"
    }

    # check for an existing record
    $rec = Get-AZTxtRecord $RecordName $zoneID

    # if the record has no etag, it means we faked it because it doesn't exist.
    # So just return
    if (!($rec.etag)) {
        Write-Verbose "Record $($rec.name) already removed."
        return
    }

    # remove the value if it exists
    $txtVals = $rec.properties.TXTRecords
    if ($TxtValue -notin $txtVals.value) {
        Write-Verbose "Record $($rec.name) doesn't contain $TxtValue. Nothing to do."
        return
    }
    $txtVals = @($txtVals | Where-Object { $_.value -ne $TxtValue })

    # delete the record if there are no values left
    if ($txtVals.Count -eq 0) {
        Write-Verbose "Deleting $($rec.name). No values left."
        try {
            Invoke-RestMethod "$($script:AZEnvironment.ResourceManagerUrl)$($rec.id)?api-version=2018-05-01" `
                -Method Delete -Headers $script:AZToken.AuthHeader @script:UseBasic | Out-Null
            return
        } catch { throw }
    }

    # build the record update json
    $recBody = @{properties=@{TTL=10;TXTRecords=$txtVals}} | ConvertTo-Json -Compress -Depth 5

    Write-Verbose "Sending updated $($rec.name)"
    Write-Debug $recBody
    try {
        $response = Invoke-RestMethod "$($script:AZEnvironment.ResourceManagerUrl)$($rec.id)?api-version=2018-05-01" `
            -Method Put -Body $recBody -Headers $script:AZToken.AuthHeader `
            -ContentType 'application/json' @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from an Azure hosted zone.

    .DESCRIPTION
        Use an App Registration service principal to remove a TXT record from an Azure DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AZSubscriptionId
        The Subscription ID of the Azure DNS zone. This can be found on the Properties page of the zone.

    .PARAMETER AZTenantId
        The Tenant or Directory ID of the Azure AD instance that controls access to your Azure DNS zone. This can be found on the Properties page of your Azure AD instance.

    .PARAMETER AZAppCred
        The username and password for an Azure AD user or service principal that has permissions to write TXT records in the specified zone. The username is the Application ID of the App Registration which can be found on its Properties page. The password is whatever was set at creation time.

    .PARAMETER AZAppUsername
        The username for an Azure AD user or service principal that has permissions to write TXT records in the specified zone. The username for a service principal is the Application ID of its associated App Registration which can be found on its properties page.

    .PARAMETER AZAppPasswordInsecure
        (DEPRECATED) The password for the principal specified by AZAppUsername.

    .PARAMETER AZCertThumbprint
        The thumbprint for a service principal's authentication certificate. This parameter should only be used from Windows. On non-Windows, please use AZCertPfx and AZPfxPassSecure parameters instead.

    .PARAMETER AZCertPfx
        The path to a service principal's PFX certificate file used for authentication.

    .PARAMETER AZPfxPassSecure
        The export password for the PFX file specified by AZCertPfx.

    .PARAMETER AZPfxPass
        (DEPRECATED) The export password for the PFX file specified by AZCertPfx.

    .PARAMETER AZAccessToken
        An existing Azure access token (JWT) to use for authorization when modifying TXT records. This is useful only for short lived instances or when the Azure authentication logic lives outside the module because access tokens are only valid for 1 hour.

    .PARAMETER AZUseIMDS
        If specified, the module will attempt to authenticate using the Azure Instance Metadata Service (IMDS). This will only work if the system is running within Azure and has been assigned a Managed Service Identity (MSI).

    .PARAMETER AZEnvironment
        The Azure cloud environment to use. Defaults to AzureCloud.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $azcred = Get-Credential
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZTenantId '22222222-2222-2222-2222-222222222222' -AZAppCred $azcred

        Removes a TXT record for the specified site with the specified value.

    .EXAMPLE
        $token = MyCustomLogin # external Azure auth
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZAccessToken $token

        Removes a TXT record using an existing Azure access token.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZUseIMDS

        Removes a TXT record from within Azure using a token from Azure Instance Metadata Service.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermadserviceprincipal

    .LINK
        https://docs.microsoft.com/en-us/azure/dns/dns-protect-zones-recordsets

    .LINK
        https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview
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

function ConvertFrom-AccessToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$AZAccessToken
    )

    # Anatomy of an access token
    # https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-token-and-claims

    # In this function we're extracting the tenant ID and expiration value from
    # the claims in the payload and returning an object that includes them along
    # with the original token value.

    # grab the payload section of the JWT
    $null,$payload,$null = $AZAccessToken.Split('.')

    # decode the claims
    $claims = $payload | ConvertFrom-Base64Url | ConvertFrom-Json -EA Stop

    # make sure the audience claim is correct
    if (-not $claims.aud -or $claims.aud -ne "$($script:AZEnvironment.ResourceManagerUrl)/") {
        Write-Debug "`$claims.aud = $($claims.aud)"
        throw "The provided access token has missing or incorrect audience claim. Expected: $($script:AZEnvironment.ResourceManagerUrl)/"
    }

    # make sure the token hasn't expired
    $expires = [DateTimeOffset]::FromUnixTimeSeconds($claims.exp)
    if ((Get-DateTimeOffsetNow) -gt $expires) {
        throw "The provided access token expired since $($expires.ToString('u'))"
    }

    # return an object that contains the 'expires_on' property along with the token
    # which is what we care about from the other normal logon methods
    return [pscustomobject]@{
        expires_on = $claims.exp
        access_token = $AZAccessToken
        tenant = $claims.tid
    }
}

function Connect-AZTenant {
    [CmdletBinding(DefaultParameterSetName='Credential')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(ParameterSetName='Credential',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZTenantId,
        [Parameter(ParameterSetName='Credential',Mandatory)]
        [pscredential]$AZAppCred,
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZAppUsername,
        [Parameter(ParameterSetName='DeprecatedCredentialInsecure',Mandatory)]
        [string]$AZAppPasswordInsecure,
        [Parameter(ParameterSetName='CertThumbprint',Mandatory)]
        [string]$AZCertThumbprint,
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [string]$AZCertPfx,
        [Parameter(ParameterSetName='CertFile',Mandatory)]
        [securestring]$AZPfxPassSecure,
        [Parameter(ParameterSetName='DeprecatedCertFile',Mandatory)]
        [string]$AZPfxPass,
        [Parameter(ParameterSetName='Token',Mandatory)]
        [string]$AZAccessToken,
        [Parameter(ParameterSetName='IMDS',Mandatory)]
        [switch]$AZUseIMDS,
        [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
        [string]$AZEnvironment = 'AzureCloud',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    Set-AZEnvironment $AZEnvironment

    # https://docs.microsoft.com/en-us/azure/active-directory/develop/v1-oauth2-client-creds-grant-flow
    # https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-certificate-credentials

    if ('Token' -eq $PSCmdlet.ParameterSetName) {
        # for explicit token payloads, always overwrite the cached token value
        Write-Debug "Attempting to parse explicit access token"
        $token = ConvertFrom-AccessToken $AZAccessToken
        Write-Verbose "Authenticating with provided access token for tenant $($token.tenant)"
        $script:AZToken = [pscustomobject]@{
            Expires    = [DateTimeOffset]::FromUnixTimeSeconds($token.expires_on).AddMinutes(-5)
            AuthHeader = @{ Authorization = "Bearer $($token.access_token)" }
            Tenant     = $token.tenant
        }
        return
    }

    # return if we already have a valid Bearer token unless the Tenant has changed
    if ($script:AZToken ) {
        # No $AZTenantId here means IMDS which we should be fine to cache
        if (-not $AZTenantId -or $AZTenantId -eq $script:AZToken.Tenant) {
            Write-Debug "Current token for tenant $($script:AZToken.Tenant) expires: $($script:AZToken.Expires)"
            if ((Get-DateTimeOffsetNow) -lt $script:AZToken.Expires) {
                Write-Debug "Existing token has not expired."
                return
            }
        }
    }

    if ('IMDS' -eq $PSCmdlet.ParameterSetName) {
        # If the module is running from an Azure resource utilizing Managed Service Identity (MSI),
        # we can get an access token via the Instance Metadata Service (IMDS):
        # https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/how-to-use-vm-token#get-a-token-using-azure-powershell
        # Azure Automation apparently requires a different metadata endpoint as described here:
        # https://learn.microsoft.com/en-us/azure/automation/enable-managed-identity-for-automation#get-access-token-for-system-assigned-managed-identity-using-http-get
        # Arc-enabled Servers use the same IDENTITY_ENDPOINT as Azure Automation, but seem to require the api-version parameter where Azure Automation doesn't.
        # https://learn.microsoft.com/en-us/azure/azure-arc/servers/managed-identity-authentication
        # Arc supported versions: 2021-02-01 2020-06-01 2019-11-01 2019-08-15
        Write-Verbose "Authenticating with Instance Metadata Service (IMDS)"

        $body = @{
            'api-version' = '2021-02-01'
            resource = "$($script:AZEnvironment.ResourceManagerUrl)/"
        }
        $headers = @{ Metadata='true' }

        # check for the IDENTITY_ENDPOINT environment variable
        if (-not [String]::IsNullOrWhiteSpace($env:IDENTITY_ENDPOINT)) {
            Write-Debug "Found env IDENTITY_ENDPOINT: $($env:IDENTITY_ENDPOINT)"
            $metadataUri = $env:IDENTITY_ENDPOINT

            # check for the IDENTITY_HEADER environment variable
            if (-not [String]::IsNullOrWhiteSpace($env:IDENTITY_HEADER)) {
                Write-Debug "Found env IDENTITY_HEADER: $($env:IDENTITY_HEADER)"
                $headers.'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER
            }
        } else {
            # use the default/VM metadata endpoint
            Write-Debug "Using default/VM metadata endpoint"
            $metadataUri = 'http://169.254.169.254/metadata/identity/oauth2/token'
        }

        try {
            $tokResponse = Invoke-RestMethod $metadataUri -Body $body -Headers $headers @script:UseBasic -EA Stop
        } catch {
            # Arc-enabled servers will send a 401 response prompting to retry with Basic auth using the contents
            # of a local file specified in the WWW-Authenticate header.
            # But the way we access the headers in the response is different between PowerShell 5.1 and 7+ because
            # the .NET types are significantly different.
            if ($_.Exception.Response -and 401 -eq $_.Exception.Response.StatusCode) {
                $exHeaders = $_.Exception.Response.Headers
                if ('WwwAuthenticate' -in $exHeaders.PSObject.Properties.Name) {
                    $authHeader = $exHeaders.WwwAuthenticate.Parameter
                } elseif ('WWW-Authenticate' -in $exHeaders) {
                    $authHeader = $exHeaders['WWW-Authenticate']
                } else {
                    Write-Debug "No WWW-Authenticate header found. Re-throwing exception"
                    throw
                }
                # parse the file name and get the contents
                Write-Debug "WWW-Authenticate header: $authHeader"
                $keyFile = $authHeader.Split('=')[1]
                $key = Get-Content $keyFile -Raw
                # re-try with the requested Basic auth
                try {
                    Write-Debug "Retrying with Basic auth using key with length $($key.Length)"
                    $headers.Authorization = "Basic $key"
                    $tokResponse = Invoke-RestMethod $metadataUri -Body $body -Headers $headers @script:UseBasic -EA Stop
                } catch {
                    throw
                }
            } else {
                throw
            }
        }

    } elseif ($PSCmdlet.ParameterSetName -in 'Credential','DeprecatedCredentialInsecure') {
        # We need the plaintext password to authenticate with.
        if ('Credential' -eq $PSCmdlet.ParameterSetName) {
            $AZAppUsername = $AZAppCred.UserName
            $AZAppPasswordInsecure = $AZAppCred.GetNetworkCredential().Password
        }

        Write-Verbose "Authenticating with password based credential"
        $clientId = [uri]::EscapeDataString($AZAppUsername)
        $clientSecret = [uri]::EscapeDataString($AZAppPasswordInsecure)
        $resource = [uri]::EscapeDataString("$($script:AZEnvironment.ManagementUrl)/")
        $authBody = "grant_type=client_credentials&client_id=$clientId&client_secret=$clientSecret&resource=$resource"
        try {
            $tokResponse = Invoke-RestMethod "$($script:AZEnvironment.ActiveDirectoryUrl)/$($AZTenantId)/oauth2/token" `
                -Method Post -Body $authBody @script:UseBasic -EA Stop
        } catch { throw }

    } elseif ($PSCmdlet.ParameterSetName -in 'CertThumbprint','CertFile','DeprecatedCertFile') {

        if ('CertThumbprint' -eq $PSCmdlet.ParameterSetName) {
            Write-Debug "Looking for cert thumbprint $AZCertThumbprint"
            # Look up the cert based on the thumbprint
            # check CurrentUser first
            if (-not ($cert = Get-Item "Cert:\CurrentUser\My\$AZCertThumbprint" -EA Ignore)) {
                # check LocalMachine
                if (-not ($cert = Get-Item "Cert:\LocalMachine\My\$AZCertThumbprint" -EA Ignore)) {
                    throw "Certificate with thumbprint $AZCertThumbprint not found in CurrentUser or LocalMachine stores."
                }
            }
        } else {
            Write-Debug "Looking for cert pfx $AZCertPfx"
            $AZCertPfx = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($AZCertPfx)

            # get the previously cached values
            $cachedFiles = Import-PluginVar 'AZPfxObj'
            if (-not $cachedFiles -or $cachedFiles -is [string]) {
                $cachedFiles = [pscustomobject]@{}
            }

            if (Test-Path $AZCertPfx -PathType Leaf) {

                Write-Debug "Using pfx file"
                $AZPfxObj = [IO.File]::ReadAllBytes($AZCertPfx)

                # add the contents to our cached files
                $b64Contents = ConvertTo-Base64Url -Bytes $AZPfxObj
                $cachedFiles | Add-Member $AZCertPfx $b64Contents -Force
                Export-PluginVar 'AZPfxObj' $cachedFiles

            } elseif ($AZCertPfx -in $cachedFiles.PSObject.Properties.Name) {

                Write-Warning "AZCertPfx not found at `"$AZCertPfx`". Attempting to use cached key data."
                $b64Contents = $cachedFiles.$AZCertPfx
                try {
                    $AZPfxObj = [byte[]]($b64Contents | ConvertFrom-Base64Url -AsByteArray)
                    Write-Debug $AZPfxObj.GetType().ToString()
                } catch { throw }

            } else {
                throw "AZCertPfx not found at `"$AZCertPfx`" and no cached data exists."
            }

            # We're working with a PFX file, so import into an X509Certificate2 object
            try {
                if ('CertFile' -eq $PSCmdlet.ParameterSetName) {
                    $AZPfxPass = [pscredential]::new('a',$AZPfxPassSecure).GetNetworkCredential().Password
                }
                $cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
                    $AZPfxObj,
                    $AZPfxPass,
                    [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
                )
            } catch { throw }
        }

        # make sure it has a private key attached that won't break
        if (-not $cert.HasPrivateKey) {
            throw "Private key missing for certificate with thumbprint $($cert.Thumbprint)."
        }
        if ($null -eq $cert.PrivateKey -or $cert.PrivateKey -isnot [Security.Cryptography.AsymmetricAlgorithm]) {
            throw "Private key invalid for certificate with thumbprint $($cert.Thumbprint)."
        }
        $privKey = $cert.PrivateKey
        if ($privKey -isnot [Security.Cryptography.RSACryptoServiceProvider]) {
            # On non-Windows, the private key ends up being of type RSAOpenSsl
            # which for some reason doesn't allow reading of the KeySize attribute
            # which then breaks New-Jws's internal validation checks. So we need
            # to convert it to an RSACryptoServiceProvider object instead.
            $keyParams = $privKey.ExportParameters($true)
            $privKey = [Security.Cryptography.RSACryptoServiceProvider]::new()
            $privKey.ImportParameters($keyParams)
        }

        Write-Verbose "Authenticating with certificate based credential"
        $clientId = [uri]::EscapeDataString($AZAppUsername)
        $assertType = [uri]::EscapeDataString('urn:ietf:params:oauth:client-assertion-type:jwt-bearer')
        $resource = [uri]::EscapeDataString("$($script:AZEnvironment.ManagementUrl)/")

        # build the JWT
        $jwtHead = @{
            alg = 'RS256'
            typ = 'JWT'
            x5t = ConvertTo-Base64Url -Bytes $cert.GetCertHash()
        }
        $jwtClaim = @{
            aud = "$($script:AZEnvironment.ActiveDirectoryUrl)/$($AZTenantId)/oauth2/token"
            nbf = [DateTimeOffset]::Now.ToUnixTimeSeconds().ToString()
            exp = ([DateTimeOffset]::Now.ToUnixTimeSeconds() + 3600).ToString()
            iss = $AZAppUsername
            sub = $AZAppUsername
            jti = (New-Guid).ToString()   # apparently a random guid works rather than needing to query the KeyId of the actual credential
        }
        $payload = $jwtClaim | ConvertTo-Json -Compress
        try {
            $jwt = New-Jws $privKey $jwtHead $payload -Compact -NoHeaderValidation -EA Stop
        } catch { throw }

        $authBody = "grant_type=client_credentials&client_id=$clientId&resource=$resource&client_assertion_type=$assertType&client_assertion=$jwt"
        try {
            $tokResponse = Invoke-RestMethod "$($script:AZEnvironment.ActiveDirectoryUrl)/$($AZTenantId)/oauth2/token" `
                -Method Post -Body $authBody @script:UseBasic -EA Stop
        } catch { throw }
    }

    Write-Debug "Retrieved token expiration: $($tokResponse.expires_on)"
    $token = ConvertFrom-AccessToken $tokResponse.access_token

    # create a token object we can use for subsequent calls with a 5 min buffer on the expiration
    $script:AZToken = [pscustomobject]@{
        Expires    = [DateTimeOffset]::FromUnixTimeSeconds($token.expires_on).AddMinutes(-5)
        AuthHeader = @{ Authorization = "Bearer $($token.access_token)" }
        Tenant     = $token.tenant
    }
}

function Get-AZZoneId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$AZSubscriptionId
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:AZRecordZones) { $script:AZRecordZones = @{} }

    # check for the record in the cache
    if ($script:AZRecordZones.ContainsKey($RecordName)) {
        return $script:AZRecordZones.$RecordName
    }

    # https://docs.microsoft.com/en-us/rest/api/dns/zones/list
    # Since there's currently no way to check a specific zone exists without knowing its
    # associated resource group, we need to get the list of all zones associated with the
    # subscription. There's also no way to filter the list server side and the maximum results
    # per query is 100. So we basically have to keep querying until there's no 'nextLink' in
    # the response.
    $url = "$($script:AZEnvironment.ResourceManagerUrl)/subscriptions/$($AZSubscriptionId)/providers/Microsoft.Network/dnszones?api-version=2018-05-01"
    $zones = @()
    do {
        Write-Debug "Querying zones list page"
        try {
            $response = Invoke-RestMethod $url -Headers $script:AZToken.AuthHeader @script:UseBasic
        } catch { throw }
        # grab the public zones from the response
        $zones += $response.value | Where-Object { $_.properties.zoneType -eq 'Public' }
        $url = $response.nextLink
    } while ($null -ne $url)
    Write-Verbose "$($zones.Count) zone(s) found"

    # Since Azure could be hosting both apex and sub-zones, we need to find the closest/deepest
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
        Write-Verbose "Checking $zoneTest"

        if ($zoneTest -in $zones.name) {

            # check for duplicate zones
            $zoneMatches = @($zones | Where-Object { $_.name -eq $zoneTest })
            if ($zoneMatches.Count -gt 1) {
                Write-Verbose "$($zoneMatches.Count) public copies of $zoneTest zone found: `n$(($zoneMatches.id -join "`n"))"

                # check for a 'poshacme' tag
                $taggedMatches = @($zoneMatches | Where-Object { $_.tags.poshacme })
                if ($taggedMatches.Count -eq 1) {
                    Write-Verbose "Using 'poshacme' tagged copy of the zone."
                    $zoneID = $taggedMatches[0].id
                } elseif ($taggedMatches.Count -eq 0) {
                    throw "$($zoneMatches.Count) public copies of $zoneTest zone found. Please use 'poshacme' tag on the live copy. See plugin usage guide for details."
                } else {
                    throw "$($taggedMatches.Count) public copies of $zoneTest are tagged with 'poshacme'. Please remove all but one to indicate which copy is live. See plugin usage guide for details."
                }
            } else {
                # no dupes, first match is the winner
                $zoneID = $zoneMatches[0].id
            }

            $script:AZRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}

function Get-AZTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ZoneId
    )

    # parse the zone name from the zone id and strip it from $RecordName
    # to get the relativeRecordSetName
    $zoneName = $ZoneID.Substring($ZoneID.LastIndexOf('/')+1)
    $relName = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if ($relName -eq [string]::Empty) {
        $relName = '@'
    }

    $recID = "$ZoneID/TXT/$($relName)"

    # query the specific record we're looking to modify
    Write-Verbose "Querying $RecordName"
    try {
        $rec = Invoke-RestMethod "$($script:AZEnvironment.ResourceManagerUrl)$($recID)?api-version=2018-05-01" `
            -Headers $script:AZToken.AuthHeader @script:UseBasic
    } catch {}

    if ($rec) {
        return $rec
    } else {
        # build a fake (no etag) empty record to send back
        $rec = @{id=$recID; name=$relName; properties=@{fqdn="$RecordName."; TXTRecords=@()}}
        return $rec
    }
}

function Set-AZEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
        [string]
        $azEnvironment
    )
    # The documentation for the endpoints is scattered across the developer guides for the different clouds on MSDN
    # But the most consolidated place was in the azure-cli repo
    # https://github.com/Azure/azure-cli/blob/dev/src/azure-cli-core/azure/cli/core/cloud.py

    $AzureCloud = @{
        ManagementUrl = "https://management.core.windows.net"
        ResourceManagerUrl = "https://management.azure.com"
        ActiveDirectoryUrl = "https://login.microsoftonline.com"
    }
    $AzureUSGovernment = @{
        ManagementUrl = "https://management.core.usgovcloudapi.net"
        ResourceManagerUrl = "https://management.usgovcloudapi.net"
        ActiveDirectoryUrl = "https://login.microsoftonline.us"
    }
    $AzureGermanCloud = @{
        ManagementUrl = "https://management.core.cloudapi.de"
        ResourceManagerUrl= "https://management.microsoftazure.de"
        ActiveDirectoryUrl = "https://login.microsoftonline.de"
    }
    $AzureChinaCloud = @{
        ManagementUrl = "https://management.core.chinacloudapi.cn"
        ResourceManagerUrl = "https://management.chinacloudapi.cn"
        ActiveDirectoryUrl = "https://login.chinacloudapi.cn"
    }

    $CloudEnvironments = @{
        AzureCloud = $AzureCloud
        AzureUSGovernment = $AzureUSGovernment
        AzureGerman = $AzureGermanCloud
        AzureChinaCloud = $AzureChinaCloud
    }

    $script:AZEnvironment = $CloudEnvironments[$azEnvironment]
}
