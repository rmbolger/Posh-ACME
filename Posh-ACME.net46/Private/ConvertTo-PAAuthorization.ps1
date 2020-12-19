function ConvertTo-PAAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ResponseBody,
        [Parameter(Mandatory,Position=1)]
        [string]$Location
    )

    # Most of what a user cares about in an authorization object is the challenge
    # data. To make processing easier, we're going to flatten the challenge data
    # so you don't have to loop into a sub-array. This may get unwieldy if too
    # many additional challenge types are added in the future.

    $auth = $ResponseBody | ConvertFrom-Json

    # inject the type name
    $auth.PSObject.TypeNames.Insert(0,'PoshACME.PAAuthorization')

    # Workaround non-compliant ACME servers such as Nexus CM that don't include
    # the status field on challenge objects. Just copy the auth's status to
    # each challenge.
    $nonCompliantServer = $false
    $auth.challenges | ForEach-Object {
        if ('status' -notin $_.PSObject.Properties.Name) {
            $nonCompliantServer = $true
            $_ | Add-Member -MemberType NoteProperty -Name 'status' -Value $auth.status
        }
    }
    if ($nonCompliantServer) {
        Write-Warning "ACME server returned non-compliant challenge objects with no status. Please report this to your ACME server vendor."
    }

    # According to RFC 8555 7.1.4 the expires property is only REQUIRED when the property status is "valid".
    # It's OPTIONAL for any other status and some CA's will not return it.
    # Only repair the timestamp if it actually exists
    if ('expires' -in $auth.PSObject.Properties.Name) {
        # fix any dates that may have been parsed by PSCore's JSON serializer
        $auth.expires = Repair-ISODate $auth.expires
    }

    # add "nice to have" members to the auth object
    # add members that expose the details of the 'dns-01' and 'http-01'
    # challenge in the root of the object
    $auth | Add-Member -NotePropertyMembers @{
        DNSId        = $auth.identifier.value
        fqdn         = "$(if ($auth.wildcard) {'*.'})$($auth.identifier.value)"
        location     = $Location
        DNS01Status  = $null
        DNS01Url     = $null
        DNS01Token   = $null
        HTTP01Status = $null
        HTTP01Url    = $null
        HTTP01Token  = $null
    }

    $dnsChallenge = $auth.challenges | Where-Object { $_.type -eq 'dns-01' }
    if ($dnsChallenge) {
        $auth.DNS01Status = $dnsChallenge.status
        $auth.DNS01Url    = $dnsChallenge.url
        $auth.DNS01Token  = $dnsChallenge.token
    }

    $httpChallenge = $auth.challenges | Where-Object { $_.type -eq 'http-01' }
    if ($httpChallenge) {
        $auth.HTTP01Status = $httpChallenge.status
        $auth.HTTP01Url    = $httpChallenge.url
        $auth.HTTP01Token  = $httpChallenge.token
    }

    $auth
}
