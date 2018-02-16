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
        [string]$CustomACMEServer
    )

    Begin {

        # determine which ACME server to use
        if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
            $DirUri = $script:WellKnownDirs[$WellKnownACMEServer]
        } else {
            $DirUri = $CustomACMEServer
        }

        # refresh the directory info (which should also populate $script:NextNonce)
        Update-ACMEDirectory $DirUri

    }

    Process {
        Write-Host $($Domain.Count)
    }

    End {}
}