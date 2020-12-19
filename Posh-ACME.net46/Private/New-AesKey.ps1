function New-AesKey {
    [CmdletBinding()]
    param(
        [ValidateSet(128,192,256)]
        [int]$BitLength=256
    )

    # create a random AES key with the specified length
    # BitLength / 8 = ByteLength
    $key = [byte[]]::new($BitLength/8)
    try {
        $rng = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
        $rng.GetBytes($key)
    }
    finally {
        if ($null -ne $rng) { $rng.Dispose() }
    }

    # return it as Base64Url
    ConvertTo-Base64Url -Bytes $key
}
