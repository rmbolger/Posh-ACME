function Import-WindowsChain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ChainFile,
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine'
    )

    if (-not (Test-Path $ChainFile -PathType Leaf)) {
        Write-Error "Chain file not found: $ChainFile"
        return
    }

    $pems = @(Split-PemChain -ChainFile $ChainFile)

    try {
        # open the LocalMachine\CA store for writing
        $store = [Security.Cryptography.X509Certificates.X509Store]::new('CA',$StoreLocation)
        $store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

        # loop through the returned intermediates
        $pems | ForEach-Object {

            # decode the lines into the cert's byte array
            $certBase64 = $_[1..($_.Count-2)] -join ''
            $certBytes = [Convert]::FromBase64String($certBase64)

            try {
                # create the cert object we can import
                $cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new($certBytes)

                # add the cert if it doesn't already exist
                if ($cert.Thumbprint -notin $store.Certificates.Thumbprint) {
                    Write-Verbose "Adding chain cert '$($cert.Subject)' with thumbprint $($cert.Thumbprint) to $StoreLocation\CA store."
                    $store.Add($cert)
                } else {
                    Write-Verbose "Chain cert '$($cert.Subject)' with thumbprint $($cert.Thumbprint) already exists in $StoreLocation\CA store."
                }
            }
            finally {
                # cleanup
                if ($null -ne $cert) { $cert.Dispose() }
            }

        }

        # close the store
        $store.Close()
    }
    finally {
        # cleanup
        if ($null -ne $store) { $store.Dispose() }
    }

}
