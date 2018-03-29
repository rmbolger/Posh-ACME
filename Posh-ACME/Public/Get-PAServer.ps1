function Get-PAServer {
    [CmdletBinding()]
    param(
        [switch]$List
    )

    if ($List) {
        # read the contents of each server's dir.txt
        Get-ChildItem "$($script:ConfigRoot)\*\dir.txt" | Get-Content | Sort-Object

    } else {

        $script:DirUrl

    }

}
