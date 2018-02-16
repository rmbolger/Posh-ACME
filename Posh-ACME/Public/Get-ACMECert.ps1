function Get-ACMECert {
    [CmdletBinding(DefaultParameterSetName='WellKnown')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [string[]]$Contact,
        [switch]$AcceptTOS,
        [Parameter(ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnownACMEServer='LE_STAGE',
        [Parameter(ParameterSetName='Custom')]
        [string]$CustomACMEServer,
        [ValidateScript({Test-ValidKeyLength $_})]
        [string]$AccountKeyLength='2048'
    )

    Begin {

        # We want to make sure we have a valid directory specified
        # But we don't want to overwrite a saved one unless they explicitly
        # specified a new one
        if ([string]::IsNullOrWhiteSpace($script:cfg.CurrentDir) -or
            ('WellKnownACMEServer' -in $PSBoundParameters.Keys -or 'CustomACMEServer' -in $PSBoundParameters.Keys)) {

            # determine which ACME server to use
            if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
                $DirUri = $script:WellKnownDirs[$WellKnownACMEServer]
                Set-ACMEConfig -WellKnownACMEServer $WellKnownACMEServer
            } else {
                $DirUri = $CustomACMEServer
                Set-ACMEConfig -CustomACMEServer $CustomACMEServer
            }

        }

        # refresh the directory info (which should also populate $script:NextNonce)
        Update-ACMEDirectory $script:cfg.CurrentDir
        $curcfg = $script:cfg.$script.CurrentDir

        # check if we have an existing account key
        if ($curcfg.AccountKey) {

        }



        Write-Host $AccountKeyLength
        Write-Host (Test-ValidKeyLength $AccountKeyLength)



    }

    Process {
        Write-Host $($Domain.Count)
    }

    End {}
}