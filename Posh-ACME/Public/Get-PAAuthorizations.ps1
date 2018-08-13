function Get-PAAuthorizations {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('authorizations')]
        [string[]]$AuthURLs
    )

    # Every order has an array of authorization URLs. GET'ing that URL will
    # retrieve the current state of the authorization object which we want to
    # return to the caller. However, most of what a caller would care about is
    # the state of the associated challenges for that authorization.

    # To make processing easier, we're going to flatten the challenge data so you don't
    # have to loop into a sub-array. This may get unwieldy if too many additional
    # challenge types are added in the future.

    Process {
        foreach ($AuthUrl in $AuthUrls) {

            # request the object
            try {
                $auth = Invoke-RestMethod $AuthUrl -Verbose:$false @script:UseBasic
            } catch {
                if ($_.ErrorDetails.Message -like '*Expired authorization*') {
                    Write-Warning "Authorization has expired. Unable to retrieve details."
                    continue
                } else { throw }
            }
            # inject the type name
            $auth.PSObject.TypeNames.Insert(0,'PoshACME.PAAuthorization')
            Write-Debug "Response: $($auth | ConvertTo-Json)"

            # add "nice to have" members to the auth object
            $auth | Add-Member -MemberType NoteProperty -Name 'DNSId' -Value $auth.identifier.value
            $auth | Add-Member -MemberType NoteProperty -Name 'fqdn' -Value "$(if ($auth.wildcard) {'*.'})$($auth.DNSId)"
            $auth | Add-Member -MemberType NoteProperty -Name 'location' -Value $AuthUrl

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

            # add members that expose the details of the 'http-01' challenge
            # in the root of the object
            $auth | Add-Member -MemberType NoteProperty -Name 'HTTP01Status' -Value $null
            $auth | Add-Member -MemberType NoteProperty -Name 'HTTP01Url' -Value $null
            $auth | Add-Member -MemberType NoteProperty -Name 'HTTP01Token' -Value $null

            $httpChallenge = $auth.challenges | Where-Object { $_.type -eq 'http-01' }
            if ($httpChallenge) {
                $auth.HTTP01Status = $httpChallenge.status
                $auth.HTTP01Url    = $httpChallenge.url
                $auth.HTTP01Token  = $httpChallenge.token
            }

            Write-Output $auth

        }
    }





    <#
    .SYNOPSIS
        Get the authorizations associated with a particular order or set of authorization URLs.

    .DESCRIPTION
        Returns details such as fqdn, status, expiration, and challenges for one or more ACME authorizations.

    .PARAMETER AuthURLs
        One or more authorization URLs. You also pipe in one or more PoshACME.PAOrder objects.

    .EXAMPLE
        Get-PAAuthorizations https://acme.example.com/authz/1234567

        Get the authorization for the specified URL.

    .EXAMPLE
        Get-PAOrder | Get-PAAuthorizations

        Get the authorizations for the current order on the current account.

    .EXAMPLE
        Get-PAOrder -List | Get-PAAuthorizations

        Get the authorizations for all orders on the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        New-PAOrder

    #>
}
