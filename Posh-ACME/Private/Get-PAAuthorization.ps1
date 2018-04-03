function Get-PAAuthorization {
    [OutputType('PoshACME.PAAuthorization')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string[]]$AuthUrls
    )

    # Every order has an array of authorization URLs. GET'ing that URL will
    # retrieve the current state of the authorization object which we want to
    # return to the caller. However, most of what a caller would care about is
    # the state of the associated challenges for that authorization.

    # To make processing easier and because this module only currently cares about
    # the dns-01 challenges, we're going to flatten the challenge data so you don't
    # have to loop into a sub-array. This may get unwieldy if we end up supporting
    # additional challenge types later or they create a dns-02 (or beyond) type.

    Process {

        foreach ($AuthUrl in $AuthUrls) {

            # request the object and inject the type name
            $auth = Invoke-RestMethod $AuthUrl
            $auth.PSObject.TypeNames.Insert(0,'PoshACME.PAAuthorization')
            Write-Verbose ($auth | ConvertTo-Json)

            # add the identifier domain to the root (ACME only currently supports identifier type='dns')
            $auth | Add-Member -MemberType NoteProperty -Name 'DNSId' -Value $auth.identifier.value
            $auth | Add-Member -MemberType NoteProperty -Name 'fqdn' -Value "$(if ($auth.wildcard) {'*.'})$($auth.DNSId)"

            # add members that expose the details of the 'dns-01' challenge
            # in the root of the object
            $auth | Add-Member -MemberType NoteProperty -Name 'DNS01Status' -Value $null
            $auth | Add-Member -MemberType NoteProperty -Name 'DNS01Url' -Value $null
            $auth | Add-Member -MemberType NoteProperty -Name 'DNS01Token' -Value $null

            $dnsChallenge = $auth.challenges | Where-Object { $_.type -eq 'dns-01' }
            if ($dnsChallenge) {
                $auth.DNS01Status = $dnsChallenge.status
                $auth.DNS01Url    = $dnsChallenge.url
                $auth.DNS01Token  = $dnsChallenge.token
            }

            Write-Output $auth

        }

    }

}
