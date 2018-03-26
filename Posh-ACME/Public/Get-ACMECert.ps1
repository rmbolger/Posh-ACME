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
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='2048'
    )

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
    $curcfg = $script:cfg.($script:cfg.CurrentDir)

    # import the existing account key or create a new one
    try {
        $acctKey = $curcfg.AccountKey | ConvertFrom-Jwk -EA Stop
        $SavedKey = $true

        # warn if they specified an AccountKeyLength that we won't be using
        if ($PSBoundParameters.ContainsKey('AccountKeyLength')) {
            Write-Warning 'Existing account key found. Ignoring -AccountKeyLength parameter.'
        }
    } catch {
        # existing key either doesn't exist or is corrupt
        # so we need to generate a new one
        Write-Verbose 'Creating account key.'
        $acctJwk = New-Jwk $AccountKeyLength
        Set-ACMEConfig -AccountKey $acctJwk -EA Stop
        $acctKey = $acctJwk | ConvertFrom-Jwk
    }

    # make sure we have a valid AccountUri
    if ([string]::IsNullOrWhiteSpace($curcfg.AccountUri)) {
        Set-ACMEConfig -AccountUri (Get-ACMEAccount $acctKey $Contact -AcceptTOS)
    }

    Write-Verbose "AccountUri = $($curcfg.AccountUri)"

    New-ACMEOrder

}
