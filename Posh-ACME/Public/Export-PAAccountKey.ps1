function Export-PAAccountKey {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0)]
        [string]$ID,
        [Parameter(Mandatory)]
        [string]$OutputFile,
        [switch]$Force
    )

    try {

        # make sure we have a server configured
        if (-not (Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }

        # throw an error if there's no current account and no ID passed in
        if (-not $ID -and -not ($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run New-PAAccount or specify an account ID."
        }

        # make sure the ID is valid if specified
        if ($ID -and -not ($acct = Get-PAAccount $ID)) {
            throw "Invalid account ID: $ID"
        }

        # confirm overwrite unless -Force was specified
        if (-not $Force -and (Test-Path $OutputFile -PathType Leaf) -and
            -not $PSCmdlet.ShouldContinue("Overwrite?","$OutputFile already exists.")
        ) {
            Write-Verbose "Export account key aborted."
            return
        }

        Write-Verbose "Exporting account $($acct.id) ($($acct.KeyLength)) to $OutputFile"

        # convert the JWK to a BC keypair
        $keypair = $acct.key | ConvertFrom-Jwk -AsBC

        # export it
        Export-Pem $keypair $OutputFile

    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }


    <#
    .SYNOPSIS
        Get ACME order details.

    .DESCRIPTION
        Returns details such as Domains, key length, expiration, and status for one or more ACME orders previously created.

    .PARAMETER ID
        The ACME account ID value.

    .PARAMETER OutputFile
        The path to the file to write the key data to.

    .PARAMETER Force
        If specified and the output file already exists, it will be overwritten. Without the switch, a confirmation prompt will be presented.

    .EXAMPLE
        Export-PAAccountKey -OutputFile .\mykey.pem

        Exports the current ACME account's key to the specified file.

    .EXAMPLE
        Export-PAAccountKey 12345 -OutputFile .\mykey.pem -Force

        Exports the specified ACME account's key to the specified file and overwrites it if necessary.

    .EXAMPLE
        $fldr = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AcmeAccountKeys'
        PS C:\>New-Item -ItemType Directory -Force -Path $fldr | Out-Null
        PS C:\>Get-PAAccount -List | %{
        PS C:\>    Export-PAAccountKey $_.ID -OutputFile "$fldr\$($_.ID).key" -Force
        PS C:\>}

        Backup all account keys for this ACME server to a folder on the desktop.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAccount

    #>
}
