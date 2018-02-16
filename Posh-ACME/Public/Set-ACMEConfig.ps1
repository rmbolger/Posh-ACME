function Set-ACMEConfig {
    [CmdletBinding(DefaultParameterSetName='WellKnown')]
    param(
        [Parameter(ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnownACMEServer='LE_STAGE',
        [Parameter(ParameterSetName='Custom')]
        [string]$CustomACMEServer
    )


    if ('WellKnownACMEServer' -in $PSBoundParameters.Keys -or 'CustomACMEServer' -in $PSBoundParameters.Keys) {
        # grab the appropriate directory URI
        if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
            $DirUri = $script:WellKnownDirs[$WellKnownACMEServer]
        } else {
            $DirUri = $CustomACMEServer
        }

        # create the config entry for this Uri if it doesn't exist
        if (!$script:cfg.$DirUri) {
            $script:cfg.$DirUri = @{
                Accounts = @{}
            }

        }

    }



}
