function Convert-DirToFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DirUrl
    )

    $DirFolder = $DirUrl.Replace('https://','').Replace(':','_')
    $DirFolder = Join-Path $script:ConfigRoot $DirFolder.Substring(0,$DirFolder.IndexOf('/'))

    return $DirFolder
}