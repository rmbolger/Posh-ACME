function Get-PAServer {
    [CmdletBinding()]
    param(
        [switch]$List
    )

    if ($List) {
        # read the contents of each server's dir.txt
        Get-Content "$($script:ConfigRoot)\*\dir.txt" | Sort-Object

    } else {

        $script:CurrentDir

    }

}
