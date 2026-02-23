function Unpublish-DnsPersistChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [string]$IssuerDomainName,
        [Parameter(Mandatory,Position=2)]
        [string]$AccountUri,
        [switch]$AllowWildcard,
        [DateTimeOffset]$PersistUntil,
        [Parameter(Mandatory)]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string]$Plugin,
        [Parameter()]
        [hashtable]$PluginArgs
    )

    # dot source the plugin file
    $pluginDetail = $script:Plugins.$Plugin
    . $pluginDetail.Path

    # build the TXT value based on the input parameters
    $txtValue = '{0}; accounturi={1}' -f $IssuerDomainName, $AccountUri
    if ($AllowWildcard) {
        $txtValue += '; policy=wildcard'
    }
    if ($PersistUntil) {
        $txtValue += '; persistUntil={0}' -f $PersistUntil.ToUnixTimeSeconds()
    }
    $txtValue = '"{0}"' -f $txtValue

    # All plugins in $script:Plugins should have been validated during module
    # load. So we're not going to do much plugin-specific validation here.
    Write-Verbose "Unpublishing dns-persist-01 challenge for $Domain using Plugin $Plugin."

    # sanitize the $Domain if it was passed in as a wildcard on accident
    if ($Domain -and $Domain.StartsWith('*.')) {
        Write-Warning "Stripping wildcard characters from domain name. Not required for publishing."
        $Domain = $Domain.Substring(2)
    }

    $recordName = "_validation-persist.$($Domain)".TrimEnd('.')

    # call the function with the required parameters and splatting the rest
    Write-Debug "Calling $Plugin plugin to remove $recordName TXT with value $txtValue"
    Remove-DnsTxt -RecordName $recordName -TxtValue $txtValue @PluginArgs

}
