function Merge-PluginArgs {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [hashtable]$PluginArgs,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    # IMPORTANT: This function does not yet work on non-Windows OSes unless there is no
    # "secure" data in the hashtable. This is a known bug related to the SecureString
    # implementation (or lack thereof) on non-Windows. I'm tracking the issue via this
    # PowerShell issue:
    # https://github.com/PowerShell/PowerShell/issues/1654

    # Each time someone creates a new cert with a particular set of plugin args,
    # we're saving them to the account so they can be used automatically on additional
    # certs and renewals. Passed in args take priority. So if there are conflicts,
    # the new ones win and the old ones are overwritten.

    # Rather than using JSON like we do with everything else, we'll be using XML
    # because the JSON conversion doesn't support serializing things like SecureString
    # and PSCredential objects. But XML does via Export-CliXml/Import-CliXml.

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

    # build the path to the plugin file and import it
    $pFile = Join-Path (Join-Path $script:DirFolder $Account.id) 'plugindata.xml'
    if (Test-Path -Path $pFile -PathType Leaf) {
        Write-Debug "Loading saved plugin data"

        # import the existing file
        $merged = Import-CliXml $pFile

    } else {
        # create an empty hashtable
        $merged = @{}
    }

    # merge the incoming args
    if ($PluginArgs) {
        foreach ($key in $PluginArgs.Keys) {
            Write-Debug "Overwriting PluginArgs key $key"
            $merged.$key = $PluginArgs.$key
        }
    }

    # export the merged object
    $merged | Export-Clixml $pFile -Force

    # return the merged object
    return $merged
}
