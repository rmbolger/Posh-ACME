function New-PACSR {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,

        [Parameter(ParameterSetName='NewKey',Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='4096',

        [Parameter(ParameterSetName='OldKey',Position=1)]
        [ValidateScript({Test-ValidKey $_ -ThrowOnFail})]
        [Security.Cryptography.AsymmetricAlgorithm]$Key
    )

    # create the private key if necessary
    if ('NewKey' -eq $PSCmdlet.ParameterSetName) {
        $Key = New-PAKey $CertKeyLength
    }

    

}
