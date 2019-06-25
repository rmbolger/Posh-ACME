function Set-PAServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$SkipCertificateCheck
    )

    # convert WellKnown names to their associated Url
    if ($DirectoryUrl -notlike 'https://*') {
        $DirectoryUrl = $script:WellKnownDirs.$DirectoryUrl
    }
    Write-Debug "Using DirectoryUrl $DirectoryUrl"

    # make sure we're actually changing servers before doing anything else
    if (!$script:Dir -or !$script:Dir.location -or $DirectoryUrl -ne $script:Dir.location) {

        # reset child object references
        $script:Acct = $null
        $script:AcctFolder = $null
        $script:Order = $null
        $script:OrderFolder = $null

        # deal with cert validation options between PS editions
        if ($SkipCertificateCheck) {
            Write-Debug "skipping cert validation"
            if ($script:SkipCertSupported) {
                $script:UseBasic.SkipCertificateCheck = $true
            } else {
                [CertValidation]::Ignore()
            }
        } else {
            Write-Debug "restoring cert validation"
            if ($script:SkipCertSupported) {
                $script:UseBasic.SkipCertificateCheck = $false
            } else {
                [CertValidation]::Restore()
            }
        }

        Update-PAServer $DirectoryUrl -SkipCertificateCheck:$SkipCertificateCheck.IsPresent

        # save to disk
        $DirectoryUrl | Out-File (Join-Path (Get-ConfigRoot) 'current-server.txt') -Force -EA Stop

        # reload config from disk
        Import-PAConfig 'Server'

        # Show a link to the TOS if this server has no accounts associated with it yet.
        if (!(Get-PAAccount -List)) {
            Write-Host "Please review the Terms of Service here: $($script:Dir.meta.termsOfService)"
        }
    }





    <#
    .SYNOPSIS
        Set the current ACME server.

    .DESCRIPTION
        Use this function to switch between ACME servers. Switching also refreshes the cached data for the new server.

    .PARAMETER DirectoryUrl
        Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production v2) and LE_STAGE (LetsEncrypt Staging v2).

    .PARAMETER SkipCertificateCheck
        If specified, disable certificate validation while using this server. This should not be necessary except in development environments where you are connecting to a self-hosted ACME server.

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
