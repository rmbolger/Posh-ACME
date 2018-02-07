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

# setup some module wide variables
$script:LE_PROD = 'https://acme-v02.api.letsencrypt.org/'
$script:LE_STAGE = 'https://acme-staging-v02.api.letsencrypt.org/'
$script:NextNonce = ''
$script:UserAgent = "Posh-ACME/0.1 PowerShell/$($PSVersionTable.PSVersion)"
$script:CommonHeaders = @{'Accept-Language'='en-us,en;q=0.5'}
$script:ContentType = 'application/jose+json'

# Set the config path based on edition/platform
if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
    $script:ConfigFolder = Join-Path $env:LOCALAPPDATA 'Posh-ACME'
} elseif ($IsLinux) {
    $script:ConfigFolder = Join-Path $env:HOME '.config/Posh-ACME'
} elseif ($IsMacOs) {
    $script:ConfigFolder = Join-Path $env:HOME 'Library/Preferences/Posh-ACME'
} else {
    throw "Unrecognized PowerShell platform"
}
