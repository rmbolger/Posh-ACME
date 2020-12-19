function Test-SecureStringNotNullOrEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [securestring]$SecureString,
        [switch]$ThrowOnFail
    )

    $errorMessage = 'The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.'

    # we can get the length without decrypting, so check that first
    if ($SecureString.Length -le 0) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] $errorMessage
        }
        return $false
    }

    $strPlain = [pscredential]::new('u',$SecureString).GetNetworkCredential().Password

    if ([String]::IsNullOrEmpty($strPlain)) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] $errorMessage
        }
        return $false
    }

    return $true
}
