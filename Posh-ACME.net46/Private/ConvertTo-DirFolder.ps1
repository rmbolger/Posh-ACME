function ConvertTo-DirFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DirectoryUrl
    )

    # strip the http prefix and replace port-related colon with underscore
    $dirFolder = $DirectoryUrl.Replace('https://','').Replace(':','_')

    # strip everything following the hostname and add the config root
    $dirFolder = Join-Path (Get-ConfigRoot) $dirFolder.Substring(0,$dirFolder.IndexOf('/'))

    return $dirFolder
}
