function Import-PluginArgs {
    [CmdletBinding()]
    param(
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

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
    $pluginFile = Join-Path (Join-Path $script:DirFolder $Account.id) 'plugindata.xml'
    if (Test-Path -Path $pluginFile -PathType Leaf) {
        Write-Debug "Loading existing plugin data"

        # import the existing file
        $pArgs = Import-CliXml $pluginFile
        return $pArgs

    } else {
        # no file, so just return an empty hashtable
        return @{}
    }

}
