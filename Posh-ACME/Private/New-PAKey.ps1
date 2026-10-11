function New-PAKey {
    [CmdletBinding(DefaultParameterSetName='Generate')]
    [OutputType([PSObject])]
    param(
        [Parameter(ParameterSetName='Generate',Position=0)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048',
        [Parameter(ParameterSetName='FromPem',Mandatory)]
        [string]$KeyFile
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

            $newKey = [Security.Cryptography.ECDsa]::Create($Curve)

        } else {
            $KeyType = 'RSA'
            $KeySize = [int]::Parse($KeyLength)
            Write-Debug "Creating new $KeyType $KeySize key"

            $newKey = [Security.Cryptography.RSACryptoServiceProvider]::new($KeySize)
        }

        $outputKeyLength = $KeyLength

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

        # Determine the KeyLength value based on the imported key's properties.
        $outputKeyLength = $newKey.KeySize.ToString()
        if ($newKey -is [Security.Cryptography.ECDsa]) {
            $outputKeyLength = "ec-$outputKeyLength"
        }
        Write-Debug "KeyLength parsed as $outputKeyLength"

        try {
            Test-ValidKeyLength $outputKeyLength -ThrowOnFail | Out-Null
        } catch {
            throw "Imported key length ($outputKeyLength) is invalid. $($_.Exception.Message)"
        }
    }

    $keyJwk = $newKey | ConvertTo-Jwk
    $pubKeyJwk = $newKey | ConvertTo-Jwk -PublicOnly
    $pubKeyJwkJson = $pubKeyJwk | ConvertTo-Json -Depth 5 -Compress
    $pubKeyJwkBytes = [Text.Encoding]::UTF8.GetBytes($pubKeyJwkJson)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $thumbprint = ConvertTo-Base64Url ($sha256.ComputeHash($pubKeyJwkBytes))

    return [pscustomobject]@{
        Key = $newKey
        KeyLength = $outputKeyLength
        JwkKey = $keyJwk
        JwkPubKey = $pubKeyJwk
        JwkThumbprint = $thumbprint
    }
}
