#Requires -Version 5.1

# Before we do anything else, make sure we have a sufficient .NET version that can load
# the .NET Standard 2.0 version of Bouncy Castle we're using. It's supposed to be compatible
# with .NET 4.6.1, but only if the app is compiled to support it (which PowerShell is not).
# So it only loads properly on .NET 4.7.1 or later which is also the minimum version we need
# to fully support ECC based certs. Any version of .NET Core should already work.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    # https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#to-check-for-a-minimum-required-net-framework-version-by-querying-the-registry-in-powershell-net-framework-45-and-later
    $netBuild = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
    if ($netBuild -ge 461308) { <# 4.7.1+ - all good #> }
    else {
        if     ($netBuild -ge 460798) { $netVer = '4.7' }
        elseif ($netBuild -ge 394802) { $netVer = '4.6.2' }
        elseif ($netBuild -ge 394254) { $netVer = '4.6.1' }
        elseif ($netBuild -ge 393295) { $netVer = '4.6' }
        elseif ($netBuild -ge 379893) { $netVer = '4.5.2' }
        elseif ($netBuild -ge 378675) { $netVer = '4.5.1' }
        Write-Warning "**********************************************************************"
        Write-Warning "Insufficient .NET version. Found .NET $netVer (build $netBuild)."
        Write-Warning ".NET 4.7.1 or later is required to ensure proper functionality."
        Write-Warning "**********************************************************************"
    }
}

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
$script:WellKnownDirs = @{
    LE_PROD = 'https://acme-v02.api.letsencrypt.org/directory';
    LE_STAGE = 'https://acme-staging-v02.api.letsencrypt.org/directory';
}
$script:HEADER_NONCE = 'Replay-Nonce'
$script:USER_AGENT = "Posh-ACME/2.7.1 PowerShell/$($PSVersionTable.PSVersion)"
$script:COMMON_HEADERS = @{'Accept-Language'='en-us,en;q=0.5'}

# Invoke-WebRequest and Invoke-RestMethod on PowerShell 5.1 both use
# IE's DOM parser by default which gives you some nice things that we
# don't use like html/form parsing. The problem is that it can generate
# errors if IE is not installed or hasn't gone through the first-run
# sequence in a new profile. Fortunately, there's a -UseBasicParsing switch
# on both functions that uses a PowerShell native parser instead and avoids
# those problems. In PowerShell Core 6, the parameter has been deprecated
# because there is no IE DOM parser to use and all requests use the native
# parser by default. In order to future proof ourselves for the switch's
# eventual removal, we'll set it only if it actually exists in this
# environment.
$script:UseBasic = @{}
if ('UseBasicParsing' -in (Get-Command Invoke-WebRequest).Parameters.Keys) {
    $script:UseBasic.UseBasicParsing = $true
}

# setup the DnsPlugin argument completers
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter?view=powershell-5.1
Register-ArgumentCompleter -CommandName 'New-PACertificate','Submit-ChallengeValidation' `
    -ParameterName 'DnsPlugin' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $names = (Get-ChildItem -Path $PSScriptRoot\DnsPlugins\*.ps1 -Exclude '_Example.ps1').BaseName
    $names | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
Register-ArgumentCompleter -CommandName 'Publish-DnsChallenge','Unpublish-DnsChallenge','Save-DnsChallenge' `
    -ParameterName 'Plugin' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $names = (Get-ChildItem -Path $PSScriptRoot\DnsPlugins\*.ps1 -Exclude '_Example.ps1').BaseName
    $names | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


Import-PAConfig
