function Send-ChallengeAck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string]$ChallengeUrl,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    Begin {
        # make sure any account passed in is actually associated with the current server
        # or if no account was specified, that there's a current account.
        if (!$Account) {
            if (!($Account = Get-PAAccount)) {
                try { throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        } else {
            if ($Account.id -notin (Get-PAAccount -List).id) {
                try { throw "Specified account id $($Account.id) was not found in the current server's account list." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
        # make sure it's valid
        if ($Account.status -ne 'valid') {
            try { throw "Account status is $($Account.status)." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {

        # build the header
        $header = @{
            alg = $Account.alg
            kid = $Account.location
            nonce = $script:Dir.nonce
            url = $ChallengeUrl
        }

        # send the notification
        try {
            Invoke-ACME $header '{}' $Account -EA Stop | Out-Null
        } catch { throw }

    }




    <#
    .SYNOPSIS
        Notify the ACME server to proceed validating a challenge.

    .DESCRIPTION
        Use this after publishing the required resource for one of the challenges from an authorization object. It lets the ACME server know that it should proceed validating that challenge.

    .PARAMETER ChallengeUrl
        The URL of the challenge to be validated.

    .PARAMETER Account
        The ACME account associated with the challenge.

    .EXAMPLE
        $auths = Get-PAOrder | Get-PAAuthorization

        PS C:\>Send-ChallengeAck $auths[0].DNS01Url

        Tell the ACME server to validate the first DNS challenge in the current order.

    .EXAMPLE
        $auths = Get-PAOrder | Get-PAAuthorization

        PS C:\>$httpUrls = ($auths | ?{ $_.status -eq 'pending' }).HTTP01Url
        PS C:\>$httpUrls | Send-ChallengeAck

        Tell the ACME server to validate all pending HTTP challenges in the current order.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAuthorization

    .LINK
        Submit-ChallengeValidation

    #>

}
