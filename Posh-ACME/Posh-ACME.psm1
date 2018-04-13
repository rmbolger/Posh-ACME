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
$script:USER_AGENT = "Posh-ACME/0.1 PowerShell/$($PSVersionTable.PSVersion)"
$script:COMMON_HEADERS = @{'Accept-Language'='en-us,en;q=0.5'}
$script:CONTENT_TYPE = 'application/jose+json'

Import-PAConfig
