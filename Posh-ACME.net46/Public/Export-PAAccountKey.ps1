function Export-PAAccountKey {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [Alias('Name')]
        [string]$ID,
        [Parameter(Mandatory)]
        [string]$OutputFile,
        [switch]$Force
    )

    Begin {
        # make sure we have a server configured
        if (-not (Get-PAServer)) {
            try { throw "No ACME server configured. Run Set-PAServer first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        if ($Force) {
            $ConfirmPreference = 'None'
        }
    }

    Process {
        trap { $PSCmdlet.ThrowTerminatingError($_) }

        # throw an error if there's no current account and no ID passed in
        if (-not $ID -and -not ($acct = Get-PAAccount)) {
            throw "No ACME account configured. Run New-PAAccount or specify an account ID."
        }

        # make sure the ID is valid if specified
        if ($ID -and -not ($acct = Get-PAAccount -ID $ID)) {
            throw "Invalid account ID: $ID"
        }

        # check if the output file exists
        $fileExists = Test-Path $OutputFile -PathType Leaf

        # confirm overwrite unless -Force was specified
        if ($fileExists -and -not $Force -and
            -not $PSCmdlet.ShouldContinue("Overwrite?","File already exists: $OutputFile"))
        {
            Write-Verbose "Export account key aborted."
            return
        }

        Write-Verbose "Exporting account $($acct.id) ($($acct.KeyLength)) to $OutputFile"

        # convert the JWK to a BC keypair
        $keypair = $acct.key | ConvertFrom-Jwk -AsBC

        # export it
        Export-Pem $keypair $OutputFile

    }
}
