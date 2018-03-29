function Get-PAServer {
    [CmdletBinding()]
    param(
        [switch]$List,
        [switch]$Refresh
    )

    if ($List) {
        # read the contents of each server's dir.json
        Get-ChildItem "$($script:ConfigRoot)\*\dir.json" | Get-Content -Raw |
            ConvertFrom-Json | Sort-Object location | ForEach-Object {

                # add the type name so it displays properly
                $_.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')
                Write-Output $_

            }
    } else {

        if ($Refresh) { Update-PAServer }
        $script:Dir

    }

}
