function Export-PluginArgs {
    [CmdletBinding()]
    param(
        [hashtable]$PluginArgs,
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    # Ultimately what we want to do here is serialize $PluginArgs to an
    # account specific file so that we can load them back up when it's time
    # to renew a cert. However, we don't want to just overwrite the file
    # that's currently there because there might be parameters for other
    # plugins that we'd be deleting. Instead, we basically want to merge
    # the current set with the existing set (overwriting the existing only
    # for parameters that overlap).

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
    $pluginFile = Join-Path (Join-Path $script:DirFolder $Account.id) 'plugindata.xml'
    if (Test-Path -Path $pluginFile -PathType Leaf) {
        Write-Verbose "Loading existing plugin data"

        # import the existing file
        $pArgs = Import-CliXml $pluginFile
        Write-Verbose $pArgs.GetType()

    } else {
        # create an empty hashtable
        $pArgs = @{}
        Write-Verbose $pArgs.GetType()
    }

    # loop through the keys of the incoming args
    foreach ($key in $PluginArgs.Keys) {

        # replace things that exist and add new where they don't
        $pArgs.$key = $PluginArgs.$key
    }

    # export the merged object
    $pArgs | Export-Clixml $pluginFile -Force

}
