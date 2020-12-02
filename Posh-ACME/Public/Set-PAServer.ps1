function Set-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$SkipCertificateCheck,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$DisableTelemetry,
        [switch]$NoRefresh
    )

    Process {

        # make sure we have either a DirectoryUrl or an existing active server
        if (-not $DirectoryUrl -and -not ($curDir = Get-PAServer)) {
            try { throw "No DirectoryUrl specified and no active server. Please specify a DirectoryUrl." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # convert WellKnown names to their associated Url
        if ($DirectoryUrl -and $DirectoryUrl -notlike 'https://*') {
            $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
            Write-Debug "Using DirectoryUrl $DirectoryUrl"
        }

        # determine whether we're changing servers
        if ($DirectoryUrl -and (-not $curDir -or $curDir.location -ne $DirectoryUrl)) {
            $serverChange = $true
        }

        # use the active server if an explicit one wasn't specified
        if (-not $DirectoryUrl) {
            $DirectoryUrl = $curDir.location
        }
        $dirFolder = ConvertTo-DirFolder $DirectoryUrl

        # check for first use of this server
        if (-not (Test-Path $dirFolder -PathType Container)) {
            $firstUse = $true
        }

        # prep the server metadata
        $updateParams = @{
            DirectoryUrl = $DirectoryUrl
            NoRefresh= $NoRefresh.IsPresent
        }
        if ('DisableTelemetry' -in $PSBoundParameters.Keys) {
            Write-Debug "Setting DisableTelemetry value to $($DisableTelemetry.IsPresent)"
            $updateParams.DisableTelemetry = $DisableTelemetry.IsPresent
        }
        if ('SkipCertificateCheck' -in $PSBoundParameters.Keys) {
            Write-Debug "Setting SkipCertificateCheck value to $($SkipCertificateCheck.IsPresent)"
            $updateParams.SkipCertificateCheck = $SkipCertificateCheck.IsPresent
            Set-CertValidation $updateParams.SkipCertificateCheck
        }

        # update the server metadata
        Update-PAServer @updateParams

        if ($serverChange) {
            # save as the new active server
            $DirectoryUrl | Out-File (Join-Path (Get-ConfigRoot) 'current-server.txt') -Force -EA Stop
        }

        # reload config from disk
        Import-PAConfig -Level 'Server'

        # Show a link to the TOS if this is the server's first use.
        if ($firstUse) {
            Write-Host "Please review the Terms of Service here: $($script:Dir.meta.termsOfService)"
        }
    }


    <#
    .SYNOPSIS
        Set the current ACME server and its configuration.

    .DESCRIPTION
        Use this function to switch between ACME servers or change configuration settings for a server. Switching also refreshes the cached data for the new server.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2), LE_STAGE (LetsEncrypt Staging v2), BUYPASS_PROD (BuyPass.com Production), and BUYPASS_TEST (BuyPass.com Testing).

    .PARAMETER SkipCertificateCheck
        If specified, disable certificate validation while using this server. This should not be necessary except in development environments where you are connecting to a self-hosted ACME server.

    .PARAMETER DisableTelemetry
        If specified, telemetry data will not be sent to the Posh-ACME team for actions associated with this server. The telemetry data that gets sent by default includes Posh-ACME version, PowerShell version, and generic OS platform (Windows/Linux/MacOS).

    .PARAMETER NoRefresh
        If specified, the ACME server will not be re-queried for updated endpoints or a fresh nonce. By default, it would be.

    .EXAMPLE
        Set-PAServer LE_PROD

        Switch to the LetsEncrypt production server using the short name.

    .EXAMPLE
        Set-PAServer -DirectoryUrl https://myacme.example.com/directory

        Switch to the specified ACME server using the directory URL.

    .EXAMPLE
        (Get-PAServer -List)[0] | Set-PAServer

        Switch to the first ACME server returned by "Get-PAServer -List"

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAServer

    #>
}
