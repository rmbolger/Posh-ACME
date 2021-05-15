function Test-ValidFriendlyName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$FriendlyName,
        [switch]$ThrowOnFail
    )

    # Since our friendly names ultimately correspond to filesystem paths,
    # we want to be overly cautious with the characters we allow so things
    # remain cross-platform friendly. We're also going to exclude some
    # characters that are technically cross-platform friendly but have special
    # meaning in some shells.

    $reFriendly = [regex]'^[0-9a-zA-Z-._!]+$'

    if ($FriendlyName -match $reFriendly) {
        return $true
    }

    # otherwise, fail
    if ($ThrowOnFail) {
        throw "'$_' contains incompatible characters. Please use only A-Z, a-z, 0-9, or any of '-._!'"
    } else {
        return $false
    }
}
