function New-PAKey {
    [CmdletBinding()]
    [OutputType('System.Security.Cryptography.AsymmetricAlgorithm')]
    param(
        [Parameter(Position=0)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048'
    )

    # KeyLength should have already been validated which means it should be a parseable
    # [int] that may have an "ec-" prefix
    if ($KeyLength -like 'ec-*') {
        $KeyType = 'EC'
        $KeySize = [int]::Parse($KeyLength.Substring(3))
    } else {
        $KeyType = 'RSA'
        $KeySize = [int]::Parse($KeyLength)
    }
    Write-Debug "Creating new $KeyType $KeySize key"

    # create the new key
    switch ($KeyType) {
        'RSA' {
            $Key = New-Object Security.Cryptography.RSACryptoServiceProvider $KeySize
            break;
        }
        'EC' {
            # Get the appropriate curve based on the key size
            # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.eccurve.namedcurves
            $Curve = switch ($KeySize) {
                256 { [Security.Cryptography.ECCurve+NamedCurves]::nistP256; break }
                384 { [Security.Cryptography.ECCurve+NamedCurves]::nistP384; break }
                521 { [Security.Cryptography.ECCurve+NamedCurves]::nistP521; break }
                default { throw "Unsupported EC KeySize. Try 256, 384, or 521." }
            }

            $Key = [Security.Cryptography.ECDsa]::Create($Curve)
            break;
        }
        default { throw "Unsupported key type" }
    }

    return $Key
}
