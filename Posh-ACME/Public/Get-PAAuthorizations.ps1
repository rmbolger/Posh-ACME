function Get-PAAuthorizations {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('authorizations')]
        [string[]]$AuthURLs,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    # Every order has an array of authorization URLs that can be used to
    # retrieve the current state of the authorization object which we want to
    # return to the caller. However, most of what a caller would care about is
    # the state of the associated challenges for that authorization.

    # To make processing easier, we're going to flatten the challenge data so you don't
    # have to loop into a sub-array. This may get unwieldy if too many additional
    # challenge types are added in the future.

    Begin {
        # make sure any account passed in is actually associated with the current server
        # or if no account was specified, that there's a current account.
        if (!$Account) {
            if (!($Account = Get-PAAccount)) {
                throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
            }
        } else {
            if ($Account.id -notin (Get-PAAccount -List).id) {
                throw "Specified account id $($Account.id) was not found in the current server's account list."
            }
        }
        # make sure it's valid
        if ($Account.status -ne 'valid') {
            throw "Account status is $($Account.status)."
        }
    }

    Process {
        foreach ($AuthUrl in $AuthUrls) {

            # request the object
            try {
                $header = @{alg=$Account.alg; kid=$Account.location;nonce=$script:Dir.nonce;url=$AuthUrl}
                $response = Invoke-ACME $header ([String]::Empty) $Account -EA Stop
                $auth = $response.Content | ConvertFrom-Json
            } catch [AcmeException] {
                if ($_.Exception.Data.status -eq 404) {
                    Write-Warning "Authorization not found on server. $($_.Exception.Data.detail)"
                    continue
                } else { throw }
            }
            # inject the type name
            $auth.PSObject.TypeNames.Insert(0,'PoshACME.PAAuthorization')
            Write-Debug "Response: $($auth | ConvertTo-Json)"

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

    .PARAMETER Account
        An existing ACME account object such as the output from Get-PAAccount. If no account is specified, the current account will be used.

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
