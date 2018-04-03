function Unpublish-DNSChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=2)]
        [string]$Token,
        [Parameter(Mandatory,Position=3)]
        [string]$Plugin,
        [Parameter(Position=4)]
        [hashtable]$PluginArgs
    )

    $recordName = "_acme-challenge.$Domain"

    $keyAuth = Get-KeyAuthorization $Account $Token

    # hash and encode the key authorization value
    $keyAuthBytes = [Text.Encoding]::UTF8.GetBytes($keyAuth)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $keyAuthHash = $sha256.ComputeHash($keyAuthBytes)
    $txtValue = ConvertTo-Base64Url $keyAuthHash

    Write-Verbose "Calling $Plugin plugin to remove $recordName TXT with value $txtValue"

    # dot source the plugin file
    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'
    . (Join-Path $pluginDir "$Plugin.ps1")

    # check for the command that should exist now based on plugin name
    $delCommand = "Remove-DnsChallenge$Plugin"
    if (!(Get-Command $delCommand -ErrorAction SilentlyContinue)) {
        throw "Expected plugin command $delCommand not found."
    }

    # call the function with the required parameters and splatting the rest
    &$delCommand $recordName $txtValue @PluginArgs

}
