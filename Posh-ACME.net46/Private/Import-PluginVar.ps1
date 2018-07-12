function Import-PluginVar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$VarName
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

        # return the variable requested if it exists
        if ($VarName -in $pVars.PSObject.Properties.Name) {
            return $pVars.$VarName
        } else {
            return $null
        }

    } else {
        # no file means no variable regardless of the name
        return $null
    }

}
