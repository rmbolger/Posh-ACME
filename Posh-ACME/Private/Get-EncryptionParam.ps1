function Get-EncryptionParam {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    # return early if sskey is empty or not defined
    if ([String]::IsNullOrEmpty($Account.sskey)) {
        return @{}
    }

    if ('VAULT' -ne $Account.sskey) {
        # an sskey value of anything except 'VAULT' should mean the key string
        # is directly attached to the account object
        $keyString = $Account.sskey
    }
    else {
        # retrieve the key from the SecretManagement Vault if possible

        # make sure we have the necessary SecretManagement commands available
        if (-not (Get-Command 'Unlock-SecretVault' -EA Ignore) -or
            -not (Get-Command 'Get-Secret' -EA Ignore) )
        {
            Write-Error "Unable to retrieve encryption key. Commands associated with SecretManagement module not found. Make sure Microsoft.PowerShell.SecretManagement is installed and accessible." -Category 'NotInstalled'
            return @{}
        }

        # make sure we have a vault name
        $vaultName = $env:POSHACME_VAULT_NAME
        if ([string]::IsNullOrWhiteSpace($vaultName)) {
            Write-Error "Unable to retrieve encryption key. SecretManagement Vault name not found. Make sure POSHACME_VAULT_NAME and related environment variables are defined." -Category 'ObjectNotFound'
            return @{}
        }

        # build the secret name
        if ([String]::IsNullOrEmpty($Account.VaultGuid)) {
            Write-Error "Unable to retrieve encryption key. Missing VaultGuid property on account object."
            return @{}
        }
        $secretName = "$($env:POSHACME_VAULT_SECRETPREFIX)poshacme_$($Account.VaultGuid)_sskey"

        # if a vault password is defined, explicitly unlock the vault
        if (-not [string]::IsNullOrEmpty($env:POSHACME_VAULT_PASS)) {
            $ssPass = ConvertTo-SecureString $env:POSHACME_VAULT_PASS -AsPlainText -Force
            Unlock-SecretVault -Name $vaultName -Password $ssPass
        }

        # Attempt to get the key
        try {
            Write-Debug "Attempting to retrieve secret '$secretName' from vault '$vaultName'"
            $keyString = Get-Secret -Vault $vaultName -Name $secretName -AsPlainText -EA Stop
        } catch {
            $PSCmdlet.WriteError($_)
            return @{}
        }
    }

    # return the hydrated key as a hashtable to splat
    $keyBytes = $keyString | ConvertFrom-Base64Url -AsByteArray
    return @{ Key = $keyBytes }
}
