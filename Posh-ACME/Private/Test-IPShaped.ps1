function Test-IPShaped {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$IPString,
        [switch]$ThrowOnFail
    )

    # In various circumstances, we need to validate whether a string is an IPv4 or
    # IPv6 address or neither (because it's a domain name). We don't actually care
    # if the string is a valid IP address, just whether it is shaped like one to
    # determine whether to handle it as an IP or FQDN. Server side things will do
    # the actual validation later.
    $reIPv4 = [regex]'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'

    # check if the string matches the IPv4 regex or looks like an IPv6 address (contains a colon)
    if ($IPString -match $reIPv4 -or $IPString -like '*:*') {
        return $true
    }

    if ($ThrowOnFail) {
        throw "Invalid IP address: $IPString"
    }
    return $false
}
