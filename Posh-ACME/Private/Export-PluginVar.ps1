function Export-PluginVar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$VarName,
        [Parameter(Mandatory,Position=1)]
        [object]$VarValue
    )

    if (-not ($Account = Get-PAAccount)) {
        throw "No current account selected. Try running Set-PAAccount first."
    }

    # build the path to the plugin vars file and import it
    $pVarFile = Join-Path (Join-Path (Get-DirFolder) $Account.id) 'pluginvars.json'

    if (Test-Path -Path $pVarFile -PathType Leaf) {
        # import the existing file
        Write-Debug "Loading saved plugin vars"
        $pVars = Get-Content $pVarFile -Raw | ConvertFrom-Json
    } else {
        # create an empty object
        $pVars = [pscustomobject]@{}
    }

    # add/overwrite the value
    $pVars | Add-Member $VarName $VarValue -Force

    # save the updated file
    Write-Debug "Saving updated plugin vars"
    $pVars | ConvertTo-Json -Depth 5 | Out-File $pVarFile
}
