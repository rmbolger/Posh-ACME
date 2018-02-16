#Requires -Version 5.1

# Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach($import in @($Public + $Private))
{
    Try { . $import.fullname }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename
Export-ModuleMember -Function $Private.Basename

# setup some module wide variables
$script:WellKnownDirs = @{
    LE_PROD = 'https://acme-v02.api.letsencrypt.org/directory';
    LE_STAGE = 'https://acme-staging-v02.api.letsencrypt.org/directory';
}
$script:HEADER_NONCE = 'Replay-Nonce'
$script:NextNonce = ''
$script:UserAgent = "Posh-ACME/0.1 PowerShell/$($PSVersionTable.PSVersion)"
$script:CommonHeaders = @{'Accept-Language'='en-us,en;q=0.5'}
$script:ContentType = 'application/jose+json'

# Set the config path based on edition/platform
if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
    $script:ConfigFolder = $env:LOCALAPPDATA
} elseif ($IsLinux) {
    $script:ConfigFolder = Join-Path $env:HOME '.config'
} elseif ($IsMacOs) {
    $script:ConfigFolder = Join-Path $env:HOME 'Library/Preferences'
} else {
    throw "Unrecognized PowerShell platform"
}
$script:ConfigFile = Join-Path $script:ConfigFolder 'posh-acme.json'

# Import the existing config if there is one
try {
    $cfg = Get-Content $script:ConfigFile -Encoding UTF8 -EA Stop | ConvertFrom-Json -EA Stop
    $script:cfg = $cfg
} catch {
    # throw a warning if the config file was found but just couldn't be parsed
    if (Test-Path $script:ConfigFile) {
        Write-Warning "Config file found but content is invalid. Creating new config."
        Move-Item $script:ConfigFile "$($script:ConfigFile).bad" -Force
    }

    # create a new config
    $script:cfg = [pscustomobject]@{
        CurrentDir = [string]::Empty
    }

    # write the config to disk
    $script:cfg | ConvertTo-Json | Out-File $script:ConfigFile -Encoding UTF8
}
