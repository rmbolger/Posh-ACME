#Requires -Version 5.1

# set the user module path based on edition and platform
if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop') {
    $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
} else {
    if ($IsWindows) {
        $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    } else {
        $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) '.local/share/powershell/Modules'
    }
}

# deal with execution policy on Windows
if (('PSEdition' -notin $PSVersionTable.Keys -or
     $PSVersionTable.PSEdition -eq 'Desktop' -or
     $IsWindows) -and
     (Get-ExecutionPolicy) -notin 'Unrestricted','RemoteSigned','Bypass')
{
    Write-Host "Setting user execution policy to RemoteSigned" -ForegroundColor Cyan
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# create user-specific modules folder if it doesn't exist
New-Item -ItemType Directory -Force -Path $installpath | out-null

if ([String]::IsNullOrWhiteSpace($PSScriptRoot)) {

    if ([String]::IsNullOrWhiteSpace($remoteBranch)) {
        $remoteBranch = 'main'
    }

    # GitHub now requires TLS 1.2
    # https://blog.github.com/2018-02-23-weak-cryptographic-standards-removed/
    $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__,[Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }

    # likely running from online, so download
    $url = "https://github.com/rmbolger/Posh-ACME/archive/$remoteBranch.zip"
    Write-Host "Downloading latest version of Posh-ACME from $url" -ForegroundColor Cyan
    $file = Join-Path ([system.io.path]::GetTempPath()) 'Posh-ACME.zip'
    $webclient = New-Object System.Net.WebClient
    try { $webclient.DownloadFile($url,$file) }
    catch { throw }
    Write-Host "File saved to $file" -ForegroundColor Green

    # extract the zip
    Write-Host "Uncompressing the Zip file to $($installpath)" -ForegroundColor Cyan
    Expand-Archive $file -DestinationPath $installpath

    Write-Host "Removing any old copy" -ForegroundColor Cyan
    Remove-Item "$installpath\Posh-ACME" -Recurse -Force -EA Ignore
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item "$installpath\Posh-ACME-$remoteBranch\Posh-ACME" $installpath -Recurse -Force -EA Continue
    Remove-Item "$installpath\Posh-ACME-$remoteBranch" -Recurse -Force
    Import-Module -Name Posh-ACME -Force
} else {
    # running locally
    Remove-Item "$installpath\Posh-ACME.net46" -Recurse -Force -EA Ignore
    Copy-Item "$PSScriptRoot\Posh-ACME.net46" $installpath -Recurse -Force -EA Continue
    # force re-load the module (assuming you're editing locally and want to see changes)
    Import-Module -Name Posh-ACME.net46 -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module Posh-ACME.net46
