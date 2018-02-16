function Get-ACMECert {
    [CmdletBinding()]
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

    }

    Process {
        Write-Host $($Domain.Count)
        Write-Host $WellKnownACMEServer
        Write-Host $CustomACMEServer
    }

    End {}
}