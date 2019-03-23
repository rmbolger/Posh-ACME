function New-EncKey {
    [CmdletBinding()]
    param()

    $keyPath = Get-EncKey -PathOnly

    if (Test-Path $keyPath) {
        throw "Encryption key file already exists."
    }

    # create a random 32 byte (256 bit) key which is the maximum currently
    # supported by ConvertTo/From-SecureString
    $key = New-Object byte[] 32
    $rng = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($key)

    # encode it to Base64Url and write it to the file
    ConvertTo-Base64Url -Bytes $key | Out-File $keyPath -Encoding ascii

}
