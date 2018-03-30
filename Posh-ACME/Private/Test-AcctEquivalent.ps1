function Test-AcctEquivalent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$acct,
        [Parameter(Position=1)]
        [string[]]$Contact,
        [Parameter(Position=2)]
        [string]$KeyLength
    )

    # We need an easy way to check whether a given PAAccount object
    # "matches" a set of contacts and key details. So this function
    # will return true if the specified PAAccount object contains
    # the same set of Contacts and the same key type/length as the
    # specified values.

    # compare contacts if -Contact was explicitly specified
    if ('Contact' -in $PSBoundParameters.Keys) {

        # sort and concatenate the contacts so we can easily compare
        $origContacts = ($acct.contact | sort) -join ','
        $newContacts = ($Contact | sort) -join ','

        if ($origContacts -ne $newContacts) {
            Write-Verbose "'$origContacts' -ne '$newContacts'"
            return $false
        }
    }

    # compare KeyLength if -KeyLength was explicitly specified
    if ('KeyLength' -in $PSBoundParameters.Keys) {

        if ($acct.KeyLength -ne $KeyLength) {
            Write-Verbose "'$($acct.KeyLength)' -ne '$KeyLength'"
            return $false
        }
    }

    # otherwise, return true
    return $true
}
