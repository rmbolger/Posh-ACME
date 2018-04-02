function Publish-DNSChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [string]$KeyAuthorization,
        [Parameter(Mandatory,Position=2)]
        [string]$Plugin,
        [Parameter(Position=3)]
        [hashtable]$PluginArgs
    )

    $recordName = "_acme-challenge.$Domain"

    # hash and encode the key authorization value
    $keyAuthBytes = [Text.Encoding]::UTF8.GetBytes($KeyAuthorization)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $keyAuthHash = $sha256.ComputeHash($keyAuthBytes)
    $txtValue = ConvertTo-Base64Url $keyAuthHash

    Write-Verbose "Must set $recordName TXT to $txtValue"

    # dot source the plugin file
    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'
    . (Join-Path $pluginDir "$Plugin.ps1")

    # check for the command that should exist now based on plugin name
    $addCommand = "Add-DnsChallenge$Plugin"
    if (!(Get-Command $addCommand -ErrorAction SilentlyContinue)) {
        throw "Expected plugin command $addCommand not found."
    }

    # call the function with the required parameters and splatting the rest
    &$addCommand $recordName $txtValue @PluginArgs

}
