function New-PAKey {
    [CmdletBinding(DefaultParameterSetName='Generate')]
    [OutputType('System.Security.Cryptography.AsymmetricAlgorithm')]
    param(
        [Parameter(ParameterSetName='Generate',Position=0)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048',
        [Parameter(ParameterSetName='FromPem',Mandatory)]
        [string]$KeyFile,
        [Parameter(ParameterSetName='FromPem',Mandatory)]
        [ref]$ParsedLength
    )

    if ('Generate' -eq $PSCmdlet.ParameterSetName) {

        # KeyLength should have already been validated which means it should be a parseable
        # [int] that may have an "ec-" prefix
        if ($KeyLength -like 'ec-*') {
            $KeyType = 'EC'
            $KeySize = [int]::Parse($KeyLength.Substring(3))
            Write-Debug "Creating new $KeyType $KeySize key"

            # Get the appropriate curve based on the key size
            # https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.eccurve.namedcurves
            $Curve = switch ($KeySize) {
                256 { [Security.Cryptography.ECCurve+NamedCurves]::nistP256; break }
                384 { [Security.Cryptography.ECCurve+NamedCurves]::nistP384; break }
                521 { [Security.Cryptography.ECCurve+NamedCurves]::nistP521; break }
                default { throw "Unsupported EC KeySize. Try 256, 384, or 521." }
            }

            # return the new key
            return [Security.Cryptography.ECDsa]::Create($Curve)

        } else {
            $KeyType = 'RSA'
            $KeySize = [int]::Parse($KeyLength)
            Write-Debug "Creating new $KeyType $KeySize key"

            # return the new key
            return [Security.Cryptography.RSACryptoServiceProvider]::new($KeySize)
        }

    } else {

        # make sure the file exists
        if (-not (Test-Path $KeyFile -PathType Leaf)) {
            throw "KeyFile $KeyFile not found"
        }

        Write-Verbose "Attempting to import private key $KeyFile"
        try {
            $newKey = Import-Pem -InputFile $KeyFile | ConvertFrom-BCKey
        } catch {
            throw "Error importing private key. $($_.Exception.Message)"
        }

        # determine the appropriate KeyLength value based on the imported
        # key's properties
        $kl = $newKey.KeySize.ToString()
        if ($newKey -is [Security.Cryptography.ECDsa]) {
            $kl = "ec-$kl"
        }
        Write-Debug "KeyLength parsed as $kl"

        try {
            Test-ValidKeyLength $kl -ThrowOnFail | Out-Null
            # set the [ref] value to pass back
            $ParsedLength.Value = $kl
        } catch {
            throw "Imported key length ($kl) is invalid. $($_.Exception.Message)"
        }

        # return the new key
        return $newKey
    }
}
